"""Compatibility import surface for older backend code."""

from app.services.matlab_bridge import MatlabBridge, matlab_bridge

__all__ = ["MatlabBridge", "matlab_bridge"]

