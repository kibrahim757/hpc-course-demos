import numpy as np

from qiskit import QuantumCircuit
from qiskit.circuit.library import PauliTwoDesign
from qiskit.quantum_info import SparsePauliOp
from qiskit.transpiler.preset_passmanagers import generate_preset_pass_manager
from qiskit.transpiler import PassManager
# from qiskit_ibm_runtime import EstimatorV2
from qiskit.providers.fake_provider import GenericBackendV2
from qiskit_aer.primitives import EstimatorV2

num_qubits=5
qc = PauliTwoDesign(num_qubits=num_qubits,reps=4, seed=5, insert_barriers=True)
parameters = qc.parameters

obs = SparsePauliOp.from_sparse_list([("Z", [num_qubits-2], 1)], num_qubits=num_qubits)

# Specify circuit parameter values
np.random.seed(0) # Specify the seed for debugging purpose such that the circuit is the same very time we run it
phi_max = 0.5 * np.pi
parameter_values = np.random.uniform(-1 * phi_max, phi_max, len(parameters))

# service = QiskitRuntimeService()
# backend = service.backend('ibm_sherbrooke')
backend = GenericBackendV2(num_qubits=num_qubits)

target = backend.target

# Transpile the circuit
pm = generate_preset_pass_manager(
        target=target, 
        optimization_level=1
      )

t_qc = pm.run(qc)

# Map the observables according to the transpile layout
t_obs = obs.apply_layout(t_qc.layout)

estimator = EstimatorV2()
job = estimator.run([(t_qc, t_obs, parameter_values)])
print(job.job_id())

# Get result and print 
result = job.result()
expectation_value = result[0].data.evs
expectation_value_stds = result[0].data.stds
print(f"Expectation Value: {expectation_value} ± {expectation_value_stds}")
