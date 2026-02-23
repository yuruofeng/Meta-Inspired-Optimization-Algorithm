classdef (Abstract) BaseAlgorithm < handle
    % BaseAlgorithm 抽象基类，所有元启发式算法的统一接口
    %
    % 定义了元启发式算法的基本框架和生命周期方法。所有具体算法
    % (如GA, PSO, ALO, GWO等)必须继承此类并实现抽象方法。
    %
    % 参考规范: metaheuristic_spec.md §2.1
    %
    % 使用示例:
    %   classdef MyAlgorithm < BaseAlgorithm
    %       methods
    %           function obj = MyAlgorithm(config)
    %               obj = obj@BaseAlgorithm(config);
    %           end
    %           % 实现抽象方法...
    %       end
    %   end
    %
    % 作者：RUOFENG YU
    % 版本: 1.0.0
    % 日期: 2025

    properties (Access = protected)
        config struct          % 算法配置参数
        currentIteration int64 % 当前迭代次数
        startTime double       % 开始时间
        problem                % 问题对象
    end

    properties (Access = protected, Transient)
        convergenceCurve double  % 收敛曲线
        bestSolution double      % 当前最优解
        bestFitness double       % 当前最优适应度
        totalEvaluations int64   % 总评估次数
    end

    properties (Constant)
        PARAM_SCHEMA struct = struct()  % 参数元数据，子类应覆盖
    end

    methods
        function obj = BaseAlgorithm(configStruct)
            % BaseAlgorithm 构造函数
            %
            % 输入参数:
            %   configStruct - 配置结构体，包含算法参数
            %
            % 异常:
            %   InvalidParamError - 参数不合法时抛出

            if nargin < 1 || isempty(configStruct)
                configStruct = struct();
            end

            obj.config = obj.validateConfig(configStruct);
            obj.currentIteration = 0;
            obj.totalEvaluations = 0;
            obj.bestFitness = Inf;
        end

        function result = run(obj, problem)
            % run 执行优化过程的主入口 (模板方法)
            %
            % 此方法定义了优化的标准流程，不可被子类覆盖。
            % 子类应实现 initialize(), iterate(), shouldStop() 方法。
            %
            % 输入参数:
            %   problem - 问题对象，必须实现 evaluate() 方法
            %
            % 输出参数:
            %   result - OptimizationResult 对象，包含优化结果
            %
            % 示例:
            %   algorithm = GWO(config);
            %   result = algorithm.run(problem);
            %   fprintf('Best fitness: %.6f\\n', result.bestFitness);

            obj.startTime = tic;
            obj.problem = problem;

            % 初始化
            obj.initialize(problem);

            % 主循环
            while ~obj.shouldStop()
                obj.iterate();
                obj.currentIteration = obj.currentIteration + 1;

                % 记录收敛曲线
                obj.convergenceCurve(obj.currentIteration) = obj.bestFitness;
            end

            % 收集结果
            result = obj.collectResult();
        end
    end

    methods (Abstract)
        initialize(obj, problem)
        % initialize 初始化算法
        %
        % 输入参数:
        %   problem - 问题对象

        iterate(obj)
        % iterate 执行一次迭代
        %
        % 在此方法中更新种群，评估适应度，更新最优解

        tf = shouldStop(obj)
        % shouldStop 判断是否应该停止迭代
        %
        % 输出参数:
        %   tf - true表示停止，false表示继续

        validatedConfig = validateConfig(obj, config)
        % validatedConfig 验证并规范化配置参数
        %
        % 输入参数:
        %   config - 原始配置结构体
        %
        % 输出参数:
        %   validatedConfig - 验证后的配置结构体
    end

    methods (Access = protected)
        function result = collectResult(obj)
            % collectResult 收集优化结果
            %
            % 此方法在优化完成后调用，构造 OptimizationResult 对象。
            % 子类可以覆盖此方法以添加额外的元数据。

            elapsedTime = toc(obj.startTime);

            result = OptimizationResult(...
                'bestSolution', obj.bestSolution, ...
                'bestFitness', obj.bestFitness, ...
                'convergenceCurve', obj.convergenceCurve, ...
                'totalEvaluations', obj.totalEvaluations, ...
                'elapsedTime', elapsedTime, ...
                'metadata', struct(...
                    'algorithm', class(obj), ...
                    'iterations', obj.currentIteration, ...
                    'config', obj.config ...
                ) ...
            );
        end

        function fitness = evaluateSolution(obj, solution)
            % evaluateSolution 评估单个解的适应度
            %
            % 输入参数:
            %   solution - 待评估的解向量
            %
            % 输出参数:
            %   fitness - 适应度值

            fitness = obj.problem.evaluate(solution);
            obj.totalEvaluations = obj.totalEvaluations + 1;

            % 更新最优解
            if fitness < obj.bestFitness
                obj.bestFitness = fitness;
                obj.bestSolution = solution;
            end
        end

        function fitness = evaluatePopulation(obj, population)
            % evaluatePopulation 批量评估种群
            %
            % 输入参数:
            %   population - 种群矩阵 (N x dim)
            %
            % 输出参数:
            %   fitness - 适应度向量 (N x 1)

            popSize = size(population, 1);
            fitness = zeros(popSize, 1);

            for i = 1:popSize
                fitness(i) = obj.evaluateSolution(population(i, :));
            end
        end

        function displayProgress(obj, message)
            % displayProgress 显示进度信息
            %
            % 输入参数:
            %   message - 进度消息

            if isfield(obj.config, 'verbose') && obj.config.verbose
                fprintf('[%s] Iteration %d/%d: %s\n', ...
                    class(obj), obj.currentIteration, ...
                    obj.config.maxIterations, message);
            end
        end
    end

    methods (Static)
        function schema = getParamSchema()
            % getParamSchema 获取参数元数据
            %
            % 子类应覆盖 PARAM_SCHEMA 常量以提供参数元数据

            schema = BaseAlgorithm.PARAM_SCHEMA;
        end

        function validatedConfig = validateFromSchema(config, schema)
            % validateFromSchema 基于Schema的通用配置验证
            %
            % 从PARAM_SCHEMA常量自动验证所有参数，消除15个算法中
            % 重复的validateConfig()实现。
            %
            % 输入参数:
            %   config - 原始配置结构体
            %   schema - 参数schema结构体
            %
            % 输出参数:
            %   validatedConfig - 验证后的配置结构体
            %
            % Schema格式:
            %   schema.fieldName.type - 参数类型: 'integer', 'double', 'boolean', 'string'
            %   schema.fieldName.default - 默认值
            %   schema.fieldName.min - 最小值 (可选，用于数值类型)
            %   schema.fieldName.max - 最大值 (可选，用于数值类型)
            %   schema.fieldName.description - 参数描述 (可选)
            %
            % 使用示例:
            %   在子类的validateConfig()中:
            %   function validatedConfig = validateConfig(obj, config)
            %       validatedConfig = BaseAlgorithm.validateFromSchema(config, MyAlgorithm.PARAM_SCHEMA);
            %   end

            validatedConfig = struct();

            % 如果schema为空，直接返回原始config
            if isempty(fieldnames(schema))
                % 合并默认配置
                validatedConfig = config;
                return;
            end

            % 遍历schema中的所有字段
            fn = fieldnames(schema);
            for i = 1:length(fn)
                fieldName = fn{i};
                fieldSchema = schema.(fieldName);

                % 获取值或使用默认值
                if isfield(config, fieldName)
                    value = config.(fieldName);
                else
                    if isfield(fieldSchema, 'default')
                        value = fieldSchema.default;
                    else
                        error('BaseAlgorithm:MissingRequiredParam', ...
                            'Required parameter ''%s'' is missing', fieldName);
                    end
                end

                % 验证类型
                if isfield(fieldSchema, 'type')
                    fieldType = fieldSchema.type;

                    switch fieldType
                        case 'integer'
                            validateattributes(value, {'numeric'}, ...
                                {'scalar', 'integer'});
                            if isfield(fieldSchema, 'min')
                                validateattributes(value, {'numeric'}, ...
                                    {'scalar', '>=', fieldSchema.min});
                            end
                            if isfield(fieldSchema, 'max')
                                validateattributes(value, {'numeric'}, ...
                                    {'scalar', '<=', fieldSchema.max});
                            end
                            value = int64(value);

                        case 'double'
                            validateattributes(value, {'numeric'}, {'scalar'});
                            if isfield(fieldSchema, 'min')
                                validateattributes(value, {'numeric'}, ...
                                    {'scalar', '>=', fieldSchema.min});
                            end
                            if isfield(fieldSchema, 'max')
                                validateattributes(value, {'numeric'}, ...
                                    {'scalar', '<=', fieldSchema.max});
                            end

                        case 'boolean'
                            validateattributes(value, {'logical'}, {'scalar'});

                        case 'string'
                            validateattributes(value, {'char', 'string'}, {'scalar'});

                        otherwise
                            error('BaseAlgorithm:UnknownType', ...
                                'Unknown parameter type: %s', fieldType);
                    end
                end

                validatedConfig.(fieldName) = value;
            end

            % 添加config中不在schema里的额外字段（保持向后兼容）
            configFields = fieldnames(config);
            schemaFields = fieldnames(schema);
            for i = 1:length(configFields)
                fieldName = configFields{i};
                if ~isfield(validatedConfig, fieldName)
                    validatedConfig.(fieldName) = config.(fieldName);
                end
            end
        end
    end
end
