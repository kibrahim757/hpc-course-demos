import os
from typing import List, Dict, Optional

from qiskit import QuantumCircuit
from qiskit.circuit.library import PauliTwoDesign
from qiskit.quantum_info import SparsePauliOp
from qiskit.transpiler.preset_passmanagers import generate_preset_pass_manager
from qiskit.transpiler import PassManager
# from qiskit_ibm_runtime import EstimatorV2
from qiskit.providers.fake_provider import GenericBackendV2
from qiskit_aer.primitives import EstimatorV2 as Estimator, SamplerV2 as Sampler
from qiskit.providers import Backend


class QuantumResource:
    def __init__(self, backend):
        self.backend = backend
    
    @property
    def target(self):
        return self.backend.target



class QRMI:
    def resources(self) -> List[QuantumResource]:
        return [
            QuantumResource(
                GenericBackendV2(num_qubits=10)
            )
        ]


class EstimatorV2(Estimator):
    def __init__(self, resource: QuantumResource):
        self.resource = resource
        super().__init__()



class SamplerV2(Sampler):
    def __init__(self, resource: QuantumResource):
        self.resource = resource
        super().__init__()

