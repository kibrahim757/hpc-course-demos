import os
import json
from dotenv import load_dotenv
from qiskit.quantum_info import SparsePauliOp
from qiskit.qasm3 import loads, dumps
from qiskit.transpiler.preset_passmanagers import generate_preset_pass_manager
from qrmi.primitives import QRMIService
from qrmi.primitives.ibm import get_target

service = QRMIService()
resources = service.resources()
if len(resources) == 0:
    raise ValueError("No quantum resource is available.")

qrmi = resources[0]
target = get_target(qrmi)

num_qubits=target.num_qubits

data_folder = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
os.makedirs(data_folder, exist_ok=True)

with open(os.path.join(data_folder, "circuit.qasm")) as f:
    qc = loads(f.read())

with open(os.path.join(data_folder, "obs.json")) as f:
    obs = json.load(f)
    obs = SparsePauliOp.from_sparse_list(obs, num_qubits=num_qubits)

load_dotenv()

pm = generate_preset_pass_manager(
        target=target, 
        optimization_level=1
      )
isa_qc = pm.run(qc)

isa_obs = obs.apply_layout(isa_qc.layout)


with open(os.path.join(data_folder, "isa_circuit.qasm"), "w") as f:
    f.write(dumps(isa_qc))

obs_json = {
    "type": "SparsePauliOp",
    "paulis": isa_obs.paulis.to_labels(),
    "coeffs": [float(c) for c in isa_obs.coeffs]
}

with open(os.path.join(data_folder, "isa_obs.json"), "w") as f:
    json.dump(obs_json, f, indent=2)
