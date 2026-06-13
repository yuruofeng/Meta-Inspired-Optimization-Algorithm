"""Fallback algorithm catalog used when MATLAB metadata is unavailable."""

from copy import deepcopy
from typing import Any


SIMULATED_ALGORITHM_CATALOG = [
    {"id": "ABC", "fullName": "Artificial Bee Colony", "version": "1.0.0", "category": "swarm", "description": "Bee foraging-inspired optimizer."},
    {"id": "ACO", "fullName": "Ant Colony Optimization", "version": "1.0.0", "category": "swarm", "description": "Continuous ant colony optimizer."},
    {"id": "ALO", "fullName": "Ant Lion Optimizer", "version": "2.0.0", "category": "swarm", "description": "Ant lion-inspired population optimizer."},
    {"id": "AO", "fullName": "Aquila Optimizer", "version": "1.0.0", "category": "swarm", "description": "Aquila hunting strategy-inspired optimizer."},
    {"id": "ASO", "fullName": "Atom Search Optimization", "version": "1.0.0", "category": "physics", "description": "Atom motion-inspired optimizer."},
    {"id": "AVOA", "fullName": "African Vultures Optimization Algorithm", "version": "1.0.0", "category": "swarm", "description": "African vulture foraging-inspired optimizer."},
    {"id": "BA", "fullName": "Bat Algorithm", "version": "1.0.0", "category": "swarm", "description": "Echolocation-inspired optimizer."},
    {"id": "BBA", "fullName": "Binary Bat Algorithm", "version": "2.0.0", "category": "swarm", "description": "Binary variant of the bat algorithm."},
    {"id": "BFO", "fullName": "Bacterial Foraging Optimization", "version": "1.0.0", "category": "swarm", "description": "Bacterial chemotaxis-inspired optimizer."},
    {"id": "BDA", "fullName": "Binary Dragonfly Algorithm", "version": "2.0.0", "category": "swarm", "description": "Binary variant of the dragonfly algorithm."},
    {"id": "BWO", "fullName": "Beluga Whale Optimization", "version": "1.0.0", "category": "swarm", "description": "Beluga whale behavior-inspired optimizer."},
    {"id": "CPO", "fullName": "Crested Porcupine Optimizer", "version": "1.0.0", "category": "swarm", "description": "Crested porcupine defense-inspired optimizer."},
    {"id": "CS", "fullName": "Cuckoo Search", "version": "1.0.0", "category": "swarm", "description": "Brood parasitism and Levy flight-inspired optimizer."},
    {"id": "DA", "fullName": "Dragonfly Algorithm", "version": "2.0.0", "category": "swarm", "description": "Dragonfly swarming-inspired optimizer."},
    {"id": "DBO", "fullName": "Dung Beetle Optimizer", "version": "1.0.0", "category": "swarm", "description": "Dung beetle behavior-inspired optimizer."},
    {"id": "DE", "fullName": "Differential Evolution", "version": "1.0.0", "category": "evolutionary", "description": "Vector-difference evolutionary optimizer."},
    {"id": "EWOA", "fullName": "Enhanced Whale Optimization Algorithm", "version": "2.0.0", "category": "hybrid", "description": "Enhanced whale optimization algorithm."},
    {"id": "FA", "fullName": "Firefly Algorithm", "version": "1.0.0", "category": "swarm", "description": "Firefly attractiveness-inspired optimizer."},
    {"id": "FPA", "fullName": "Flower Pollination Algorithm", "version": "1.0.0", "category": "swarm", "description": "Flower pollination-inspired optimizer."},
    {"id": "GA", "fullName": "Genetic Algorithm", "version": "2.0.0", "category": "evolutionary", "description": "Evolutionary optimizer using selection, crossover, and mutation."},
    {"id": "GOA", "fullName": "Grasshopper Optimization Algorithm", "version": "2.0.0", "category": "swarm", "description": "Grasshopper swarming-inspired optimizer."},
    {"id": "GTO", "fullName": "Artificial Gorilla Troops Optimizer", "version": "1.0.0", "category": "swarm", "description": "Gorilla troop behavior-inspired optimizer."},
    {"id": "GWO", "fullName": "Grey Wolf Optimizer", "version": "2.0.0", "category": "swarm", "description": "Grey wolf hierarchy and hunting-inspired optimizer."},
    {"id": "HHO", "fullName": "Harris Hawks Optimization", "version": "1.0.0", "category": "swarm", "description": "Harris hawk cooperative hunting-inspired optimizer."},
    {"id": "HGS", "fullName": "Hunger Games Search", "version": "1.0.0", "category": "swarm", "description": "Hunger-driven search optimizer."},
    {"id": "HLBDA", "fullName": "Hybrid Learning Binary Dragonfly Algorithm", "version": "2.0.0", "category": "hybrid", "description": "Hybrid learning binary dragonfly optimizer."},
    {"id": "HO", "fullName": "Honey Badger Optimizer", "version": "1.0.0", "category": "swarm", "description": "Honey badger behavior-inspired optimizer."},
    {"id": "HS", "fullName": "Harmony Search", "version": "1.0.0", "category": "physics", "description": "Music improvisation-inspired optimizer."},
    {"id": "IGWO", "fullName": "Improved Grey Wolf Optimizer", "version": "2.0.0", "category": "hybrid", "description": "Improved grey wolf optimizer."},
    {"id": "JAYA", "fullName": "JAYA Algorithm", "version": "1.0.0", "category": "evolutionary", "description": "Parameter-light best-worst population optimizer."},
    {"id": "KOA", "fullName": "Kepler Optimization Algorithm", "version": "1.0.0", "category": "physics", "description": "Keplerian motion-inspired optimizer."},
    {"id": "MFO", "fullName": "Moth-Flame Optimization", "version": "2.0.0", "category": "swarm", "description": "Moth flame navigation-inspired optimizer."},
    {"id": "MOALO", "fullName": "Multi-Objective Ant Lion Optimizer", "version": "1.0.0", "category": "swarm", "description": "Multi-objective ant lion optimizer."},
    {"id": "MODA", "fullName": "Multi-Objective Dragonfly Algorithm", "version": "1.0.0", "category": "swarm", "description": "Multi-objective dragonfly optimizer."},
    {"id": "MOEAD", "fullName": "Multi-Objective Evolutionary Algorithm based on Decomposition", "version": "1.0.0", "category": "evolutionary", "description": "Decomposition-based multi-objective evolutionary optimizer."},
    {"id": "MOGOA", "fullName": "Multi-Objective Grasshopper Optimization Algorithm", "version": "1.0.0", "category": "swarm", "description": "Multi-objective grasshopper optimizer."},
    {"id": "MOGWO", "fullName": "Multi-Objective Grey Wolf Optimizer", "version": "1.0.0", "category": "swarm", "description": "Multi-objective grey wolf optimizer."},
    {"id": "MPA", "fullName": "Marine Predators Algorithm", "version": "1.0.0", "category": "swarm", "description": "Marine predator foraging-inspired optimizer."},
    {"id": "MSSA", "fullName": "Multi-Objective Salp Swarm Algorithm", "version": "1.0.0", "category": "swarm", "description": "Multi-objective salp swarm optimizer."},
    {"id": "MVO", "fullName": "Multi-Verse Optimizer", "version": "2.0.0", "category": "physics", "description": "Multi-verse theory-inspired optimizer."},
    {"id": "NRBO", "fullName": "Newton-Raphson-Based Optimizer", "version": "1.0.0", "category": "hybrid", "description": "Newton-Raphson-inspired optimizer."},
    {"id": "NSGAIII", "fullName": "Non-dominated Sorting Genetic Algorithm III", "version": "1.0.0", "category": "evolutionary", "description": "Reference-point-based multi-objective genetic algorithm."},
    {"id": "PSO", "fullName": "Particle Swarm Optimization", "version": "1.0.0", "category": "swarm", "description": "Particle velocity and social learning optimizer."},
    {"id": "PSOGSA", "fullName": "Particle Swarm Optimization Gravitational Search Algorithm", "version": "2.0.0", "category": "hybrid", "description": "Hybrid particle swarm and gravitational search optimizer."},
    {"id": "RIME", "fullName": "Rime Optimization Algorithm", "version": "1.0.0", "category": "physics", "description": "Rime ice growth-inspired optimizer."},
    {"id": "SA", "fullName": "Simulated Annealing", "version": "2.0.0", "category": "physics", "description": "Annealing-inspired stochastic optimizer."},
    {"id": "SCA", "fullName": "Sine Cosine Algorithm", "version": "2.0.0", "category": "physics", "description": "Sine-cosine movement-based optimizer."},
    {"id": "SMA", "fullName": "Slime Mould Algorithm", "version": "1.0.0", "category": "swarm", "description": "Slime mould oscillation-inspired optimizer."},
    {"id": "SSA", "fullName": "Salp Swarm Algorithm", "version": "2.0.0", "category": "swarm", "description": "Salp swarm-inspired optimizer."},
    {"id": "TLBO", "fullName": "Teaching-Learning-Based Optimization", "version": "1.0.0", "category": "evolutionary", "description": "Teacher and learner phase-based optimizer."},
    {"id": "VPPSO", "fullName": "Variable Population Particle Swarm Optimization", "version": "2.0.0", "category": "swarm", "description": "Variable population particle swarm optimizer."},
    {"id": "VPSO", "fullName": "Variant Particle Swarm Optimization", "version": "2.0.0", "category": "swarm", "description": "Particle swarm optimizer variant."},
    {"id": "WOA", "fullName": "Whale Optimization Algorithm", "version": "2.0.0", "category": "swarm", "description": "Whale bubble-net hunting-inspired optimizer."},
    {"id": "WOASA", "fullName": "Whale Optimization Algorithm with Simulated Annealing", "version": "2.0.0", "category": "hybrid", "description": "Hybrid whale optimization and simulated annealing optimizer."},
]


def build_simulated_algorithms(param_schema: dict[str, Any]) -> list[dict[str, Any]]:
    """Build schema-compatible algorithm metadata for simulation mode."""
    return [
        {
            **algorithm,
            "name": algorithm["id"],
            "paramSchema": deepcopy(param_schema),
        }
        for algorithm in SIMULATED_ALGORITHM_CATALOG
    ]
