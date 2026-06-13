function result = apiGetMetadata(type)
% APIGETMETADATA API接口：获取算法或基准函数的元数据
%
% 输入参数:
%   type - 元数据类型: 'algorithms' | 'benchmarks' | 'all'
%
% 输出参数:
%   result - JSON格式的元数据字符串
%
% 示例:
%   result = apiGetMetadata('algorithms');
%   algorithms = jsondecode(result);
%
%   result = apiGetMetadata('benchmarks');
%   benchmarks = jsondecode(result);
%
%   result = apiGetMetadata('all');
%   metadata = jsondecode(result);
%   algorithms = metadata.algorithms;
%   benchmarks = metadata.benchmarks;

    switch type
        case 'algorithms'
            data = getAlgorithmMetadata();
        case 'benchmarks'
            data = getBenchmarkMetadata();
        case 'all'
            data = struct(...
                'algorithms', {getAlgorithmMetadata()}, ...
                'benchmarks', {getBenchmarkMetadata()} ...
            );
        otherwise
            error('API:InvalidType', '无效的类型 "%s"。请使用: algorithms, benchmarks, 或 all', type);
    end

    result = jsonencode(data);
end

function algorithms = getAlgorithmMetadata()
% GETALGORITHMMETADATA 返回所有已注册算法的元数据列表

    if isempty(AlgorithmRegistry.listAlgorithms())
        registerAllAlgorithms();
    end

    algorithms = AlgorithmRegistry.listMetadata();
end
function benchmarks = getBenchmarkMetadata()
% GETBENCHMARKMETADATA 返回所有基准测试函数的元数据列表

    % 基准函数列表
    benchmarks = {
        % 单峰函数 F1-F7
        struct('id', 'F1', 'name', 'Sphere', 'type', 'Unimodal', 'dimension', 30, 'lowerBound', -100, 'upperBound', 100, 'optimalValue', 0, 'description', '简单的凸函数，用于测试收敛性');
        struct('id', 'F2', 'name', 'Rosenbrock', 'type', 'Unimodal', 'dimension', 30, 'lowerBound', -30, 'upperBound', 30, 'optimalValue', 0, 'description', '经典的优化测试函数');
        struct('id', 'F3', 'name', 'Step', 'type', 'Unimodal', 'dimension', 30, 'lowerBound', -100, 'upperBound', 100, 'optimalValue', 0);
        struct('id', 'F4', 'name', 'Quartic', 'type', 'Unimodal', 'dimension', 30, 'lowerBound', -1.28, 'upperBound', 1.28, 'optimalValue', 0);
        struct('id', 'F5', 'name', 'Schwefel 2.22', 'type', 'Unimodal', 'dimension', 30, 'lowerBound', -10, 'upperBound', 10, 'optimalValue', 0);
        struct('id', 'F6', 'name', 'Schwefel 1.2', 'type', 'Unimodal', 'dimension', 30, 'lowerBound', -65.536, 'upperBound', 65.536, 'optimalValue', 0);
        struct('id', 'F7', 'name', 'Schwefel 2.21', 'type', 'Unimodal', 'dimension', 30, 'lowerBound', -100, 'upperBound', 100, 'optimalValue', 0);

        % 多峰函数 F8-F13
        struct('id', 'F8', 'name', 'Schwefel', 'type', 'Multimodal', 'dimension', 30, 'lowerBound', -500, 'upperBound', 500, 'optimalValue', -12569.487, 'description', '全局最优点远离搜索空间中心');
        struct('id', 'F9', 'name', 'Rastrigin', 'type', 'Multimodal', 'dimension', 30, 'lowerBound', -5.12, 'upperBound', 5.12, 'optimalValue', 0, 'description', '高度多峰，大量局部最优');
        struct('id', 'F10', 'name', 'Ackley', 'type', 'Multimodal', 'dimension', 30, 'lowerBound', -32, 'upperBound', 32, 'optimalValue', 0, 'description', '具有几乎平坦的区域');
        struct('id', 'F11', 'name', 'Griewank', 'type', 'Multimodal', 'dimension', 30, 'lowerBound', -600, 'upperBound', 600, 'optimalValue', 0);
        struct('id', 'F12', 'name', 'Penalized 1', 'type', 'Multimodal', 'dimension', 30, 'lowerBound', -50, 'upperBound', 50, 'optimalValue', 0);
        struct('id', 'F13', 'name', 'Penalized 2', 'type', 'Multimodal', 'dimension', 30, 'lowerBound', -50, 'upperBound', 50, 'optimalValue', 0);

        % 固定维度多峰函数 F14-F23
        struct('id', 'F14', 'name', 'Shekel 5', 'type', 'Fixed-dimension Multimodal', 'dimension', 2, 'lowerBound', -65.536, 'upperBound', 65.536, 'optimalValue', 0.998);
        struct('id', 'F15', 'name', 'Kowalik', 'type', 'Fixed-dimension Multimodal', 'dimension', 4, 'lowerBound', -5, 'upperBound', 5, 'optimalValue', 0.0003075);
        struct('id', 'F16', 'name', 'Six-Hump Camel', 'type', 'Fixed-dimension Multimodal', 'dimension', 2, 'lowerBound', -5, 'upperBound', 5, 'optimalValue', -1.0316285);
        struct('id', 'F17', 'name', 'Branin', 'type', 'Fixed-dimension Multimodal', 'dimension', 2, 'lowerBound', -5, 'upperBound', 15, 'optimalValue', 0.397887);
        struct('id', 'F18', 'name', 'Goldstein-Price', 'type', 'Fixed-dimension Multimodal', 'dimension', 2, 'lowerBound', -2, 'upperBound', 2, 'optimalValue', 3);
        struct('id', 'F19', 'name', 'Hartman 3', 'type', 'Fixed-dimension Multimodal', 'dimension', 3, 'lowerBound', 0, 'upperBound', 1, 'optimalValue', -3.86);
        struct('id', 'F20', 'name', 'Hartman 6', 'type', 'Fixed-dimension Multimodal', 'dimension', 6, 'lowerBound', 0, 'upperBound', 1, 'optimalValue', -3.32);
        struct('id', 'F21', 'name', 'Shekel 7', 'type', 'Fixed-dimension Multimodal', 'dimension', 4, 'lowerBound', 0, 'upperBound', 10, 'optimalValue', -10.1532);
        struct('id', 'F22', 'name', 'Shekel 10', 'type', 'Fixed-dimension Multimodal', 'dimension', 4, 'lowerBound', 0, 'upperBound', 10, 'optimalValue', -10.4029);
        struct('id', 'F23', 'name', 'Shekel 10 (alt)', 'type', 'Fixed-dimension Multimodal', 'dimension', 4, 'lowerBound', 0, 'upperBound', 10, 'optimalValue', -10.5364);
    };
end
