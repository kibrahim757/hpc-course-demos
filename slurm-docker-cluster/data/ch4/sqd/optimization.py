import os
from qiskit import qpy
from qiskit.transpiler.preset_passmanagers import generate_preset_pass_manager
from qrmi import QRMI


data_folder = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
os.makedirs(data_folder, exist_ok=True)

with open(os.path.join(data_folder, "circuits.qpy"), "rb") as f:
    circuits = qpy.load(f)

qrmi = QRMI()
resources = qrmi.resources()
quantum_resource = resources[0]
target = quantum_resource.target

pass_manager = generate_preset_pass_manager(
    optimization_level=3,
    target=target
)
isa_circuits = pass_manager.run(circuits)

with open(os.path.join(data_folder, "isa_circuits.qpy"), "wb") as f:
    qpy.dump(isa_circuits, f)


print(isa_circuits[0].draw(scale=0.4))
