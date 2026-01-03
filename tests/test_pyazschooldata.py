"""
Tests for pyazschooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pyazschooldata
    assert pyazschooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pyazschooldata
    assert hasattr(pyazschooldata, 'fetch_enr')
    assert callable(pyazschooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pyazschooldata
    assert hasattr(pyazschooldata, 'get_available_years')
    assert callable(pyazschooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pyazschooldata
    assert hasattr(pyazschooldata, '__version__')
    assert isinstance(pyazschooldata.__version__, str)
