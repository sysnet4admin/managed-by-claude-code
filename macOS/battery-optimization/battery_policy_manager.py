#!/usr/bin/env python3
"""
Battery Policy Manager for macOS
Manages device-specific battery optimization policies
"""

import json
import subprocess
import sys
from pathlib import Path
from typing import Dict, Optional
from datetime import datetime


class DevicePolicyManager:
    """Manages battery optimization policies per device"""

    def __init__(self, config_dir: str = "~/.config/battery-optimizer"):
        self.config_dir = Path(config_dir).expanduser()
        self.config_dir.mkdir(parents=True, exist_ok=True)
        self.policies_file = self.config_dir / "device_policies.json"
        self.device_id = self._get_device_id()

    def _get_device_id(self) -> str:
        """Get unique device identifier using hardware UUID"""
        try:
            result = subprocess.run(
                ["system_profiler", "SPHardwareDataType"],
                capture_output=True,
                text=True,
                check=True
            )
            for line in result.stdout.split('\n'):
                if "Hardware UUID" in line:
                    return line.split(':')[1].strip()
            raise ValueError("Could not find Hardware UUID")
        except Exception as e:
            print(f"Error getting device ID: {e}", file=sys.stderr)
            sys.exit(1)

    def _get_device_name(self) -> str:
        """Get device name (Computer Name)"""
        try:
            result = subprocess.run(
                ["scutil", "--get", "ComputerName"],
                capture_output=True,
                text=True,
                check=True
            )
            return result.stdout.strip()
        except Exception:
            return "Unknown Mac"

    def _load_policies(self) -> Dict:
        """Load all device policies from file"""
        if not self.policies_file.exists():
            return {}

        try:
            with open(self.policies_file, 'r') as f:
                return json.load(f)
        except json.JSONDecodeError:
            print("Warning: Invalid policies file, creating new one", file=sys.stderr)
            return {}

    def _save_policies(self, policies: Dict) -> None:
        """Save all device policies to file"""
        with open(self.policies_file, 'w') as f:
            json.dump(policies, f, indent=2)

    def get_current_settings(self) -> Dict:
        """Get current pmset settings"""
        settings = {}

        # Get battery settings
        result = subprocess.run(
            ["pmset", "-g", "custom"],
            capture_output=True,
            text=True,
            check=True
        )

        current_mode = None
        for line in result.stdout.split('\n'):
            line = line.strip()
            if "Battery Power:" in line:
                current_mode = "battery"
            elif "AC Power:" in line:
                current_mode = "ac"
            elif current_mode and line:
                try:
                    key, value = line.split(maxsplit=1)
                    if current_mode not in settings:
                        settings[current_mode] = {}
                    settings[current_mode][key] = value
                except ValueError:
                    continue

        return settings

    def save_current_policy(self, policy_name: str = "default") -> None:
        """Save current power settings as a policy for this device"""
        policies = self._load_policies()

        current_settings = self.get_current_settings()
        device_name = self._get_device_name()

        if self.device_id not in policies:
            policies[self.device_id] = {
                "device_name": device_name,
                "policies": {}
            }

        policies[self.device_id]["policies"][policy_name] = {
            "settings": current_settings,
            "created_at": datetime.now().isoformat(),
            "last_applied": datetime.now().isoformat()
        }

        self._save_policies(policies)
        print(f"✓ Saved policy '{policy_name}' for device: {device_name}")
        print(f"  Device ID: {self.device_id}")

    def apply_policy(self, policy_name: str = "default") -> None:
        """Apply a saved policy for this device"""
        policies = self._load_policies()

        if self.device_id not in policies:
            print(f"✗ No policies found for this device", file=sys.stderr)
            sys.exit(1)

        device_policies = policies[self.device_id]["policies"]

        if policy_name not in device_policies:
            print(f"✗ Policy '{policy_name}' not found for this device", file=sys.stderr)
            print(f"  Available policies: {', '.join(device_policies.keys())}")
            sys.exit(1)

        policy = device_policies[policy_name]
        settings = policy["settings"]

        # Apply battery settings
        if "battery" in settings:
            cmd = ["sudo", "pmset", "-b"]
            for key, value in settings["battery"].items():
                cmd.extend([key, value])
            subprocess.run(cmd, check=True)

        # Apply AC settings
        if "ac" in settings:
            cmd = ["sudo", "pmset", "-c"]
            for key, value in settings["ac"].items():
                cmd.extend([key, value])
            subprocess.run(cmd, check=True)

        # Update last applied time
        policy["last_applied"] = datetime.now().isoformat()
        self._save_policies(policies)

        device_name = policies[self.device_id]["device_name"]
        print(f"✓ Applied policy '{policy_name}' for device: {device_name}")

    def list_policies(self) -> None:
        """List all policies for this device"""
        policies = self._load_policies()

        if self.device_id not in policies:
            print("No policies found for this device")
            return

        device_data = policies[self.device_id]
        device_name = device_data["device_name"]

        print(f"\nDevice: {device_name}")
        print(f"ID: {self.device_id}\n")

        if not device_data["policies"]:
            print("No policies saved yet")
            return

        print("Saved policies:")
        for name, policy in device_data["policies"].items():
            created = policy["created_at"][:10]
            last_applied = policy.get("last_applied", "Never")
            if last_applied != "Never":
                last_applied = last_applied[:10]

            print(f"\n  • {name}")
            print(f"    Created: {created}")
            print(f"    Last applied: {last_applied}")

            if "battery" in policy["settings"]:
                print(f"    Battery settings:")
                for key, value in policy["settings"]["battery"].items():
                    print(f"      {key}: {value}")

    def delete_policy(self, policy_name: str) -> None:
        """Delete a policy for this device"""
        policies = self._load_policies()

        if self.device_id not in policies:
            print(f"✗ No policies found for this device", file=sys.stderr)
            sys.exit(1)

        device_policies = policies[self.device_id]["policies"]

        if policy_name not in device_policies:
            print(f"✗ Policy '{policy_name}' not found", file=sys.stderr)
            sys.exit(1)

        del device_policies[policy_name]
        self._save_policies(policies)

        print(f"✓ Deleted policy '{policy_name}'")

    def list_all_devices(self) -> None:
        """List all devices with saved policies"""
        policies = self._load_policies()

        if not policies:
            print("No devices found")
            return

        print("\nAll devices with saved policies:\n")
        for device_id, data in policies.items():
            is_current = " (current)" if device_id == self.device_id else ""
            print(f"• {data['device_name']}{is_current}")
            print(f"  ID: {device_id}")
            print(f"  Policies: {', '.join(data['policies'].keys())}")
            print()


def main():
    """Main CLI interface"""
    import argparse

    parser = argparse.ArgumentParser(
        description="Manage battery optimization policies per Mac device"
    )

    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # Save command
    save_parser = subparsers.add_parser("save", help="Save current settings as a policy")
    save_parser.add_argument("name", nargs="?", default="default", help="Policy name")

    # Apply command
    apply_parser = subparsers.add_parser("apply", help="Apply a saved policy")
    apply_parser.add_argument("name", nargs="?", default="default", help="Policy name")

    # List command
    subparsers.add_parser("list", help="List policies for this device")

    # Delete command
    delete_parser = subparsers.add_parser("delete", help="Delete a policy")
    delete_parser.add_argument("name", help="Policy name")

    # List devices command
    subparsers.add_parser("devices", help="List all devices with policies")

    # Current command
    subparsers.add_parser("current", help="Show current power settings")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    manager = DevicePolicyManager()

    if args.command == "save":
        manager.save_current_policy(args.name)
    elif args.command == "apply":
        manager.apply_policy(args.name)
    elif args.command == "list":
        manager.list_policies()
    elif args.command == "delete":
        manager.delete_policy(args.name)
    elif args.command == "devices":
        manager.list_all_devices()
    elif args.command == "current":
        import pprint
        settings = manager.get_current_settings()
        print("\nCurrent power settings:\n")
        pprint.pprint(settings)


if __name__ == "__main__":
    main()
