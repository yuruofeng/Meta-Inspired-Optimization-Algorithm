function result = apiRunOptimization(algorithm, problemId, configJson)
% APIRUNOPTIMIZATION API接口：执行单次优化
%
% 输入参数:
%   algorithm  - 算法名称 (如 'GWO', 'ALO', 'WOA')
%   problemId  - 基准函数ID (如 'F1', 'F9')
%   configJson - JSON格式的配置字符串
%
% 输出参数:
%   result - JSON格式的优化结果字符串
%
% 示例:
%   config = '{"populationSize":30,"maxIterations":500}';
%   result = apiRunOptimization('GWO', 'F1', config);
%   data = jsondecode(result);

    % 解析配置
    try
        config = jsondecode(configJson);
    catch ME
        error('API:InvalidConfig', '无法解析配置JSON: %s', ME.message);
    end

    % 获取算法类
    try
        algClass = AlgorithmRegistry.getAlgorithm(algorithm);
    catch ME
        error('API:AlgorithmNotFound', '算法 "%s" 未注册: %s', algorithm, ME.message);
    end

    % 获取基准函数
    try
        [lb, ub, dim, fobj] = BenchmarkFunctions.get(problemId);
        problem = struct('evaluate', fobj, 'lb', lb, 'ub', ub, 'dim', dim);
    catch ME
        error('API:ProblemNotFound', '基准函数 "%s" 未找到: %s', problemId, ME.message);
    end

    % 构建配置结构体
    configStruct = struct();
    fields = fieldnames(config);
    for i = 1:length(fields)
        configStruct.(fields{i}) = config.(fields{i});
    end

    % 创建算法实例并运行
    try
        algInstance = algClass(configStruct);
        optResult = algInstance.run(problem);
    catch ME
        error('API:OptimizationFailed', '优化执行失败: %s', ME.message);
    end

    % 转换结果为JSON
    resultStruct = struct(...
        'bestSolution', {optResult.bestSolution}, ...
        'bestFitness', optResult.bestFitness, ...
        'convergenceCurve', {optResult.convergenceCurve}, ...
        'totalEvaluations', optResult.totalEvaluations, ...
        'elapsedTime', optResult.elapsedTime, ...
        'metadata', struct(...
            'algorithm', algorithm, ...
            'version', '2.0.0', ...
            'iterations', length(optResult.convergenceCurve), ...
            'config', configStruct ...
        ) ...
    );

    result = jsonencode(resultStruct);
end
