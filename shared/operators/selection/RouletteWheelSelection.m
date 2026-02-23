classdef RouletteWheelSelection < handle
    % RouletteWheelSelection 统一的轮盘赌选择实现
    %
    % 融合了三个版本的优点，支持多种使用模式：
    %   1. 函数式调用（向后兼容utils/版本）
    %   2. 对象式调用（支持GA/ALO风格）
    %   3. 支持最小化和最大化问题
    %   4. 完善的错误处理
    %
    % 使用示例:
    %   % 函数式调用（静态方法，向后兼容）
    %   idx = RouletteWheelSelection.quickSelect(weights);
    %
    %   % 对象式调用 - 单次选择
    %   selector = RouletteWheelSelection();
    %   idx = selector.selectOne(weights);
    %
    %   % 对象式调用 - 多次选择（GA风格）
    %   selector = RouletteWheelSelection('problemType', 'minimization');
    %   indices = selector.select(population, fitness, n);
    %
    % 版本: 3.0.0 (统一版本)
    % 日期: 2026

    properties
        scalingFactor double = 1      % 缩放因子
        problemType string = "minimization"  % 问题类型: "minimization" 或 "maximization"
    end

    methods
        function obj = RouletteWheelSelection(varargin)
            % RouletteWheelSelection 构造函数
            %
            % 输入参数 (可选):
            %   'scalingFactor', value - 缩放因子 (默认: 1)
            %   'problemType', value - 问题类型 (默认: 'minimization')
            %
            % 使用示例:
            %   selector = RouletteWheelSelection();
            %   selector = RouletteWheelSelection('scalingFactor', 2);
            %   selector = RouletteWheelSelection('problemType', 'maximization');

            % 解析输入参数
            if nargin > 0
                % 支持旧版单参数构造: RouletteWheelSelection(scalingFactor)
                if nargin == 1 && isnumeric(varargin{1})
                    if varargin{1} <= 0
                        error('RouletteWheelSelection:InvalidParam', ...
                            'scalingFactor must be > 0');
                    end
                    obj.scalingFactor = varargin{1};
                else
                    % 支持名称-值对构造
                    for i = 1:2:length(varargin)
                        if strcmpi(varargin{i}, 'scalingFactor')
                            if varargin{i+1} <= 0
                                error('RouletteWheelSelection:InvalidParam', ...
                                    'scalingFactor must be > 0');
                            end
                            obj.scalingFactor = varargin{i+1};
                        elseif strcmpi(varargin{i}, 'problemType')
                            obj.problemType = lower(varargin{i+1});
                            if ~ismember(obj.problemType, ["minimization", "maximization"])
                                error('RouletteWheelSelection:InvalidParam', ...
                                    'problemType must be "minimization" or "maximization"');
                            end
                        end
                    end
                end
            end
        end

        function indices = select(obj, population, fitness, n)
            % select 执行多次轮盘赌选择（GA风格）
            %
            % 输入参数:
            %   population - 种群矩阵 (N x Dim)
            %   fitness - 适应度向量 (N x 1)
            %   n - 需要选择的个体数量
            %
            % 输出参数:
            %   indices - 被选中个体的索引数组 (n x 1)
            %
            % 注意:
            %   对于最小化问题，fitness越小越好
            %   对于最大化问题，fitness越大越好

            popSize = size(population, 1);

            % 将适应度转换为选择概率
            prob = obj.fitnessToProbability(fitness);

            % 构建累积概率
            cumProb = cumsum(prob);

            % 执行选择
            indices = zeros(n, 1);
            for i = 1:n
                r = rand();
                % 找到第一个累积概率大于r的索引
                idx = find(cumProb >= r, 1, 'first');
                if isempty(idx)
                    idx = popSize;
                end
                indices(i) = idx;
            end
        end

        function idx = selectOne(obj, weights)
            % selectOne 执行单次轮盘赌选择（MVO/ALO风格）
            %
            % 输入参数:
            %   weights - 权重向量，支持正数和负数
            %
            % 输出参数:
            %   idx - 被选中个体的索引 (1 到 length(weights))
            %         如果选择失败返回 -1
            %
            % 注意:
            %   此方法支持负权重（MVO算法使用）
            %   权重越大，被选中概率越高

            % 计算累积和
            accumulation = cumsum(weights);

            % 检查累积和是否有效
            if accumulation(end) <= 0
                % 如果总权重为0或负数，随机选择一个
                idx = randi(length(weights));
                return;
            end

            % 在 [0, 累积和最大值] 范围内生成随机数
            p = rand() * accumulation(end);

            % 初始化选择的索引
            idx = -1;

            % 找到第一个累积和大于随机数的索引
            for i = 1:length(accumulation)
                if accumulation(i) > p
                    idx = i;
                    break;
                end
            end

            % 安全检查（理论上不会发生）
            if idx == -1
                idx = length(weights);
            end
        end

        function prob = fitnessToProbability(obj, fitness)
            % fitnessToProbability 将适应度转换为选择概率
            %
            % 输入参数:
            %   fitness - 适应度向量 (N x 1)
            %
            % 输出参数:
            %   prob - 选择概率向量 (N x 1)，和为1
            %
            % 转换方法:
            %   对于最小化问题，适应度越小越好
            %     使用倒数变换: value = 1 / (fitness + epsilon)
            %   对于最大化问题，适应度越大越好
            %     直接使用适应度值

            epsilon = 1e-10;  % 避免除零

            % 根据问题类型转换适应度
            if strcmp(obj.problemType, "minimization")
                % 将最小化适应度转换为选择权重
                weights = 1 ./ (fitness + epsilon);
            else
                % 最大化问题直接使用适应度
                weights = fitness;
            end

            % 应用缩放因子
            weights = weights ^ obj.scalingFactor;

            % 归一化为概率
            prob = weights / sum(weights);
        end
    end

    methods (Static)
        function idx = quickSelect(weights)
            % quickSelect 静态方法，函数式调用（向后兼容utils/版本）
            %
            % 输入参数:
            %   weights - 权重向量
            %
            % 输出参数:
            %   idx - 被选中个体的索引
            %
            % 使用示例:
            %   idx = RouletteWheelSelection.quickSelect([10, 20, 30]);

            selector = RouletteWheelSelection();
            idx = selector.selectOne(weights);
        end
    end
end
