#!/usr/bin/env python3
"""Minimal utilities - reducing boilerplate across scripts"""

import argparse
import shutil
import subprocess
import sys

# Global flag to force CLI mode
_force_cli = False


def set_cli_mode(enabled=True):
    """Force CLI interactive mode instead of bemenu"""
    global _force_cli
    _force_cli = enabled


class Script:
    """Base class for scripts with 3 modes: CLI args, mybemenu, interactive CLI"""
    
    def __init__(self, name, description=""):
        self.name = name
        self.description = description
        self.parser = argparse.ArgumentParser(description=description)
        self.parser.add_argument('-i', '--interactive', action='store_true',
                                help='Interactive CLI mode (text-based)')
        self.cli_handlers = {}
        self.menu_handlers = {}
    
    def add_arg(self, *args, **kwargs):
        """Add CLI argument"""
        action_name = kwargs.get('dest') or args[0].lstrip('-').replace('-', '_')
        handler = kwargs.pop('handler', None)
        self.parser.add_argument(*args, **kwargs)
        if handler:
            self.cli_handlers[action_name] = handler
        return self
    
    def add_menu_option(self, label, handler):
        """Add menu option for interactive modes"""
        self.menu_handlers[label] = handler
        return self
    
    def run(self):
        """Parse args and run appropriate mode"""
        args = self.parser.parse_args()
        
        # Set CLI mode if requested
        if args.interactive:
            set_cli_mode(True)
        
        # Check if any CLI arg was used (excluding interactive flag)
        cli_args_used = False
        for key, value in vars(args).items():
            if key != 'interactive' and value:
                cli_args_used = True
                break
        
        if cli_args_used:
            # CLI mode - execute handlers
            for key, value in vars(args).items():
                if key != 'interactive' and value and key in self.cli_handlers:
                    self.cli_handlers[key](value if not isinstance(value, bool) else None)
                    return
        else:
            # Interactive mode (mybemenu or CLI)
            if not self.menu_handlers:
                self.parser.print_help()
                return
            
            options = list(self.menu_handlers.keys())
            choice = menu(options, f"{self.name}:")
            
            if choice and choice in self.menu_handlers:
                self.menu_handlers[choice]()


def run(cmd, check=False):
    """Run command, return stdout or None"""
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=check)
        return r.stdout.strip()
    except subprocess.CalledProcessError:
        return None


def has(cmd):
    """Check if command exists"""
    return shutil.which(cmd) is not None


def menu(options, prompt="Select", lines=10):
    """Show menu - mybemenu or text-based CLI menu"""
    # Use bemenu only if not forced to CLI mode
    if not _force_cli and has('mybemenu'):
        try:
            text = '\n'.join(options)
            r = subprocess.run(['mybemenu', '-l', str(lines), '-p', prompt],
                              input=text, text=True, capture_output=True, check=True)
            sel = r.stdout.strip()
            return sel if sel in options else None
        except subprocess.CalledProcessError:
            pass
    
    # Interactive CLI mode
    print(f"\n{prompt}")
    for i, opt in enumerate(options, 1):
        print(f"{i}. {opt}")
    
    try:
        choice = input("\nEnter choice (number or text): ").strip()
        if choice.isdigit():
            idx = int(choice) - 1
            return options[idx] if 0 <= idx < len(options) else None
        # Try to match text
        for opt in options:
            if opt.lower() == choice.lower():
                return opt
        return None
    except (EOFError, KeyboardInterrupt):
        return None


def ask(prompt):
    """Get input from mybemenu or stdin"""
    if not _force_cli and has('mybemenu'):
        try:
            r = subprocess.run(['mybemenu', '-p', prompt],
                              text=True, capture_output=True, check=True)
            return r.stdout.strip()
        except subprocess.CalledProcessError:
            pass
    try:
        return input(f"{prompt}: ")
    except (EOFError, KeyboardInterrupt):
        return ""


def notify(msg, title=""):
    """Send notification or print to stdout"""
    if has('notify-send'):
        subprocess.run(['notify-send', title or "Notification", msg], check=False)
    else:
        # Fallback to printing
        print(f"[{title or 'Notification'}] {msg}")


def confirm(prompt):
    """Ask yes/no"""
    choice = menu(["Yes", "No"], prompt)
    if choice == "Yes":
        return True
    if choice == "No":
        return False
    # Fallback
    try:
        ans = input(f"{prompt} [y/N]: ").strip().lower()
        return ans in ("y", "yes")
    except (EOFError, KeyboardInterrupt):
        return False

