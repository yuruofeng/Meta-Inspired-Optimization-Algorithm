"""Fallback algorithm catalog used when MATLAB metadata is unavailable."""

from copy import deepcopy
from typing import Any


SIMULATED_ALGORITHM_CATALOG = [
    {"id": "ALO", "fullName": "Ant Lion Optimizer", "version": "2.0.0", "category": "swarm", "description": "Ant lion-inspired population optimizer."},
    {"id": "AO", "fullName": "Aquila Optimizer", "version": "1.0.0", "category": "swarm", "description": "Aquila hunting strategy-inspired optimizer."},
    {"id": "AVOA", "fullName": "African Vultures Optimization Algorithm", "version": "1.0.0", "category": "swarm", "description": "African vulture foraging-inspired optimizer."},
    {"id": "BBA", "fullName": "Binary Bat Algorithm", "version": "2.0.0", "category": "swarm", "description": "Binary variant of the bat algorithm."},
    {"id": "BDA", "fullName": "Binary Dragonfly Algorithm", "version": "2.0.0", "category": "swarm", "description": "Binary variant of the dragonfly algorithm."},
    {"id": "DA", "fullName": "Dragonfly Algorithm", "version": "2.0.0", "category": "swarm", "description": "Dragonfly swarming-inspired optimizer."},
    {"id": "EWOA", "fullName": "Enhanced Whale Optimization Algorithm", "version": "2.0.0", "category": "hybrid", "description": "Enhanced whale optimization algorithm."},
    {"id": "GA", "fullName": "Genetic Algorithm", "version": "2.0.0", "category": "evolutionary", "description": "Evolutionary optimizer using selection, crossover, and mutation."},
    {"id": "GOA", "fullName": "Grasshopper Optimization Algorithm", "version": "2.0.0", "category": "swarm", "description": "Grasshopper swarming-inspired optimizer."},
    {"id": "GTO", "fullName": "Artificial Gorilla Troops Optimizer", "version": "1.0.0", "category": "swarm", "description": "Gorilla troop behavior-inspired optimizer."},
    {"id": "GWO", "fullName": "Grey Wolf Optimizer", "version": "2.0.0", "category": "swarm", "description": "Grey wolf hierarchy and hunting-inspired optimizer."},
    {"id": "HGS", "fullName": "Hunger Games Search", "version": "1.0.0", "category": "swarm", "description": "Hunger-driven search optimizer."},
    {"id": "HLBDA", "fullName": "Hybrid Learning Binary Dragonfly Algorithm", "version": "2.0.0", "category": "hybrid", "description": "Hybrid learning binary dragonfly optimizer."},
    {"id": "IGWO", "fullName": "Improved Grey Wolf Optimizer", "version": "2.0.0", "category": "hybrid", "description": "Improved grey wolf optimizer."},
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
    {"id": "NSGAIII", "fullName": "Non-dominated Sorting Genetic Algorithm III", "version": "1.0.0", "category": "evolutionary", "description": "Reference-point-based multi-objective genetic algorithm."},
    {"id": "PSOGSA", "fullName": "Particle Swarm Optimization Gravitational Search Algorithm", "version": "2.0.0", "category": "hybrid", "description": "Hybrid particle swarm and gravitational search optimizer."},
    {"id": "RIME", "fullName": "Rime Optimization Algorithm", "version": "1.0.0", "category": "physics", "description": "Rime ice growth-inspired optimizer."},
    {"id": "SA", "fullName": "Simulated Annealing", "version": "2.0.0", "category": "physics", "description": "Annealing-inspired stochastic optimizer."},
    {"id": "SCA", "fullName": "Sine Cosine Algorithm", "version": "2.0.0", "category": "physics", "description": "Sine-cosine movement-based optimizer."},
    {"id": "SSA", "fullName": "Salp Swarm Algorithm", "version": "2.0.0", "category": "swarm", "description": "Salp swarm-inspired optimizer."},
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
