import os
import json
import numpy as np
from qiskit.circuit.library import pauli_two_design
from qiskit.quantum_info import SparsePauliOp
from qiskit.qasm3 import dumps
from qrmi.primitives import QRMIService
from qrmi.primitives.ibm import get_target

service = QRMIService()
resources = service.resources()
if len(resources) == 0:
    raise ValueError("No quantum resource is available.")

qrmi = resources[0]
target = get_target(qrmi)

num_qubits=target.num_qubits

qc = pauli_two_design(num_qubits=num_qubits,reps=4, seed=5, insert_barriers=True)
parameters = qc.parameters
obs = SparsePauliOp.from_sparse_list([("Z", [num_qubits-2], 1)], num_qubits=num_qubits)

phi_max = 0.5 * np.pi
parameter_values = np.random.uniform(-1 * phi_max, phi_max, len(parameters))


data_folder = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
os.makedirs(data_folder, exist_ok=True)

with open(os.path.join(data_folder, "circuit.qasm"), "w") as f:
    f.write(dumps(qc.decompose()))

with open(os.path.join(data_folder, "obs.json"), "w") as f:
    json.dump([("Z", [num_qubits-2], 1)], f)

with open(os.path.join(data_folder, "parameters.json"), "w") as f:
    json.dump(parameter_values.tolist(), f)
