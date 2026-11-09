"""Exercise FlyDSL dependency validation independently of Hub downloads."""

import importlib.util

import pytest
from packaging.version import Version

from kernels.backends import CPU, CUDA, ROCm
from kernels.python_deps import validate_dependencies


def test_flydsl_rocm_dependency():
    backend = ROCm(version=Version("10.0"))
    if importlib.util.find_spec("flydsl") is None:
        with pytest.raises(ImportError, match="requires Python dependency `flydsl`"):
            validate_dependencies("flydsl_test", ["flydsl"], backend)
    else:
        validate_dependencies("flydsl_test", ["flydsl"], backend)


def test_flydsl_missing_dependency(monkeypatch):
    monkeypatch.setattr(importlib.util, "find_spec", lambda name: None)
    with pytest.raises(ImportError, match="requires Python dependency `flydsl`"):
        validate_dependencies("flydsl_test", ["flydsl"], ROCm(version=Version("10.0")))


@pytest.mark.parametrize("backend", [CPU(), CUDA(version=Version("13.0"))])
def test_flydsl_rejected_on_other_backends(backend):
    with pytest.raises(ValueError, match="unsupported kernel dependency: flydsl"):
        validate_dependencies("flydsl_test", ["flydsl"], backend)
