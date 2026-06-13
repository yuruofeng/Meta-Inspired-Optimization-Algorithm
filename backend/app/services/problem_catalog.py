"""Static problem catalog entries owned by the backend API layer."""

ROBUST_BENCHMARK_FUNCTIONS = [
    {"id": "R1", "name": "TP_Biased1", "type": "Biased", "dimension": 2, "lowerBound": -100, "upperBound": 100, "delta": 1, "description": "偏置测试问题1 - 搜索空间存在偏置，最优解不在中心"},
    {"id": "R2", "name": "TP_Biased2", "type": "Biased", "dimension": 2, "lowerBound": -100, "upperBound": 100, "delta": 1, "description": "偏置测试问题2 - 多个偏置区域，增加搜索难度"},
    {"id": "R3", "name": "TP_Deceptive1", "type": "Deceptive", "dimension": 2, "lowerBound": 0, "upperBound": 1, "delta": 0.01, "description": "欺骗测试问题1 - 多个局部最优陷阱，容易误导算法"},
    {"id": "R4", "name": "TP_Deceptive2", "type": "Deceptive", "dimension": 2, "lowerBound": 0, "upperBound": 1, "delta": 0.01, "description": "欺骗测试问题2 - 密集的局部最优分布"},
    {"id": "R5", "name": "TP_Deceptive3", "type": "Deceptive", "dimension": 2, "lowerBound": 0, "upperBound": 2, "delta": 0.01, "description": "欺骗测试问题3 - 四个象限有不同的欺骗结构"},
    {"id": "R6", "name": "TP_Multimodal1", "type": "Multimodal", "dimension": 2, "lowerBound": 0, "upperBound": 1, "delta": 0.01, "description": "多模态测试问题1 - 大量局部最优，测试全局搜索能力"},
    {"id": "R7", "name": "TP_Multimodal2", "type": "Multimodal", "dimension": 2, "lowerBound": 0, "upperBound": 1, "delta": 0.01, "description": "多模态测试问题2 - 对称的多模态结构"},
    {"id": "R8", "name": "TP_Flat", "type": "Flat", "dimension": 2, "lowerBound": 0, "upperBound": 1, "delta": 0.01, "description": "平坦区域测试问题 - 大面积平坦区域，梯度信息稀少"},
]

ROBUST_TYPE_NAMES = {
    "Biased": "偏置函数",
    "Deceptive": "欺骗函数",
    "Multimodal": "多模态函数",
    "Flat": "平坦函数",
}

MDMTSP_FUNCTIONS = [
    {"id": "MDMTSP-S", "name": "小规模", "type": "application", "subtype": "MDMTSP", "dimension": 10, "lowerBound": 0, "upperBound": 2, "numCities": 10, "numDepots": 2, "travelersPerDepot": [1, 1], "totalTravelers": 2, "areaSize": 100, "description": "小规模多仓库多旅行商问题，10城市2仓库"},
    {"id": "MDMTSP-M", "name": "中规模", "type": "application", "subtype": "MDMTSP", "dimension": 15, "lowerBound": 0, "upperBound": 4, "numCities": 15, "numDepots": 2, "travelersPerDepot": [2, 2], "totalTravelers": 4, "areaSize": 200, "description": "中规模多仓库多旅行商问题，15城市2仓库"},
    {"id": "MDMTSP-L", "name": "大规模", "type": "application", "subtype": "MDMTSP", "dimension": 25, "lowerBound": 0, "upperBound": 6, "numCities": 25, "numDepots": 3, "travelersPerDepot": [2, 2, 2], "totalTravelers": 6, "areaSize": 300, "description": "大规模多仓库多旅行商问题，25城市3仓库"},
    {"id": "MDMTSP-XL", "name": "超大规模", "type": "application", "subtype": "MDMTSP", "dimension": 50, "lowerBound": 0, "upperBound": 12, "numCities": 50, "numDepots": 4, "travelersPerDepot": [3, 3, 3, 3], "totalTravelers": 12, "areaSize": 500, "description": "超大规模多仓库多旅行商问题，50城市4仓库"},
]

