# Conda Setup - Quick Reference

## What Was Done

### 1. Added Anaconda to PATH
The following paths have been permanently added to your user PATH environment variable:
- `D:\software\Anaconda`
- `D:\software\Anaconda\Scripts`
- `D:\software\Anaconda\condabin`

### 2. Initialized Conda for PowerShell
The `conda init powershell` command has been executed, which modified:
- `C:\Users\yuruofeng\Documents\WindowsPowerShell\profile.ps1`

This ensures conda is automatically available in new PowerShell sessions.

## Next Steps

### IMPORTANT: Restart Your Terminal
**You MUST close ALL terminal windows and open a new one for the changes to take effect.**

After opening a new PowerShell terminal, verify conda works:

```powershell
# Test 1: Check version
conda --version

# Test 2: Activate base environment
conda activate base

# Test 3: Check conda info
conda info

# Test 4: List all environments
conda env list
```

## Alternative: Use Anaconda Prompt

If you don't want to restart your terminal right now, you can use the pre-configured Anaconda Prompt:

1. Press `Win` key
2. Type "Anaconda Prompt"
3. Press Enter

This terminal already has conda configured and ready to use.

## Common Conda Commands

```powershell
# Create a new environment
conda create -n myenv python=3.9

# Activate an environment
conda activate myenv

# Deactivate current environment
conda deactivate

# List all environments
conda env list

# Install packages
conda install numpy pandas matplotlib

# Export environment to file
conda env export > environment.yml

# Create environment from file
conda env create -f environment.yml

# Remove an environment
conda env remove -n myenv
```

## Troubleshooting

### If conda still doesn't work after restarting terminal:

1. **Check if PATH was updated:**
   ```powershell
   $env:PATH -split ';' | Select-String "Anaconda"
   ```

2. **Check PowerShell execution policy:**
   ```powershell
   Get-ExecutionPolicy
   # If restricted, run:
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Manually reload PowerShell profile:**
   ```powershell
   . $PROFILE
   ```

4. **Verify profile content:**
   ```powershell
   cat $PROFILE
   ```

## Files Created

- `test_conda.ps1` - Verification script to test conda installation
- `CONDA_SETUP_GUIDE.md` - This file

## Summary

✅ PATH environment variable updated
✅ Conda initialized for PowerShell
⏳ **ACTION REQUIRED: Close and reopen your terminal**

After restarting your terminal, conda will be ready to use!
