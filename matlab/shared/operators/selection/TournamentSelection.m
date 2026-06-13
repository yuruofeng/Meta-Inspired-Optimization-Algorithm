classdef TournamentSelection < handle
    % TournamentSelection 统一的锦标赛选择实现
    %
    % 融合了两个版本的优点，支持两种模式：
    %   1. k-way锦标赛（GA风格） - 从k个候选中选择最优
    %   2. 二进制锦标赛（WOASA风格） - 从2个候选中选择，带探索参数
    %
    % 使用示例:
    %   % k-way锦标赛（默认）
    %   selector = TournamentSelection('mode', 'kway', 'tournamentSize', 3);
    %   indices = selector.select(population, fitness, n);
    %
    %   % 二进制锦标赛
    %   selector = TournamentSelection('mode', 'binary', 'explorationProb', 0.8);
    %   idx = selector.select(fitness);
    %
    % 版本: 3.0.0 (统一版本)
    % 日期: 2026

    properties
        mode string = "kway"              % 模式: "kway" 或 "binary"
        tournamentSize integer = 3        % k-way锦标赛大小
        explorationProb double = 0.8      % 二进制锦标赛探索概率
        problemType string = "minimization"  % 问题类型
    end

    methods
        function obj = TournamentSelection(varargin)
            % TournamentSelection 构造函数
            %
            % 输入参数 (可选):
            %   'mode', value - 选择模式: 'kway' 或 'binary' (默认: 'kway')
            %   'tournamentSize', value - k-way锦标赛大小 (默认: 3)
            %   'explorationProb', value - 二进制锦标赛探索概率 (默认: 0.8)
            %   'problemType', value - 问题类型 (默认: 'minimization')
            %
            % 旧版兼容:
            %   TournamentSelection(3) - k-way锦标赛，大小为3
            %   TournamentSelection(0.7) - 二进制锦标赛，探索概率0.7

            % 支持旧版单参数构造
            if nargin == 1 && isnumeric(varargin{1})
                param = varargin{1};
                if param > 1
                    % 视为k-way锦标赛大小
                    obj.mode = "kway";
                    if param < 2
                        error('TournamentSelection:InvalidParam', ...
                            'tournamentSize must be >= 2');
                    end
                    obj.tournamentSize = round(param);
                else
                    % 视为二进制锦标赛探索概率
                    obj.mode = "binary";
                    if param < 0 || param > 1
                        error('TournamentSelection:InvalidParam', ...
                            'explorationProb must be in [0, 1]');
                    end
                    obj.explorationProb = param;
                end
            else
                % 支持名称-值对构造
                for i = 1:2:length(varargin)
                    if strcmpi(varargin{i}, 'mode')
                        obj.mode = lower(varargin{i+1});
                        if ~ismember(obj.mode, ["kway", "binary"])
                            error('TournamentSelection:InvalidParam', ...
                                'mode must be "kway" or "binary"');
                        end
                    elseif strcmpi(varargin{i}, 'tournamentSize')
                        if varargin{i+1} < 2
                            error('TournamentSelection:InvalidParam', ...
                                'tournamentSize must be >= 2');
                        end
                        obj.tournamentSize = round(varargin{i+1});
                    elseif strcmpi(varargin{i}, 'explorationProb')
                        if varargin{i+1} < 0 || varargin{i+1} > 1
                            error('TournamentSelection:InvalidParam', ...
                                'explorationProb must be in [0, 1]');
                        end
                        obj.explorationProb = varargin{i+1};
                    elseif strcmpi(varargin{i}, 'problemType')
                        obj.problemType = lower(varargin{i+1});
                        if ~ismember(obj.problemType, ["minimization", "maximization"])
                            error('TournamentSelection:InvalidParam', ...
                                'problemType must be "minimization" or "maximization"');
                        end
                    end
                end
            end
        end

        function varargout = select(obj, varargin)
            % select 执行锦标赛选择
            %
            % k-way模式:
            %   indices = select(obj, population, fitness, n)
            %   输入:
            %     population - 种群矩阵 (N x Dim)
            %     fitness - 适应度向量 (N x 1)
            %     n - 需要选择的个体数量
            %   输出:
            %     indices - 被选中个体的索引数组 (n x 1)
            %
            % binary模式:
            %   idx = select(obj, fitness)
            %   输入:
            %     fitness - 适应度向量 (N x 1)
            %   输出:
            %     idx - 被选中个体的索引
            %
            % 注意:
            %   对于最小化问题，fitness越小越好
            %   对于最大化问题，fitness越大越好

            switch obj.mode
                case "kway"
                    [population, fitness, n] = deal(varargin{:});
                    indices = obj.kwaySelect(population, fitness, n);
                    varargout{1} = indices;
                case "binary"
                    fitness = varargin{1};
                    if nargin == 3
                        % select(fitness, n) - 选择多个
                        n = varargin{2};
                        indices = obj.binarySelectMultiple(fitness, n);
                        varargout{1} = indices;
                    else
                        % select(fitness) - 选择单个
                        idx = obj.binarySelect(fitness);
                        varargout{1} = idx;
                    end
            end
        end

        function indices = kwaySelect(obj, population, fitness, n)
            % kwaySelect k-way锦标赛选择实现（来自GA版本）
            %
            % 输入参数:
            %   population - 种群矩阵 (N x Dim)
            %   fitness - 适应度向量 (N x 1)
            %   n - 需要选择的个体数量
            %
            % 输出参数:
            %   indices - 被选中个体的索引数组 (n x 1)

            popSize = size(population, 1);
            indices = zeros(n, 1);

            for i = 1:n
                % 随机选择tournamentSize个候选
                candidates = randperm(popSize, obj.tournamentSize);

                % 根据问题类型找出最优者
                if strcmp(obj.problemType, "minimization")
                    [~, bestIdx] = min(fitness(candidates));
                else
                    [~, bestIdx] = max(fitness(candidates));
                end
                indices(i) = candidates(bestIdx);
            end
        end

        function idx = binarySelect(obj, fitness)
            % binarySelect 二进制锦标赛选择实现（来自WOASA版本）
            %
            % 输入参数:
            %   fitness - 适应度向量 (N x 1)
            %
            % 输出参数:
            %   idx - 被选中个体的索引
            %
            % 算法:
            %   1. 随机选择两个候选个体
            %   2. 生成随机数 r
            %   3. 若 r < explorationProb: 选择适应度更优者
            %   4. 否则: 选择适应度较差者（探索）

            populationSize = length(fitness);

            % 随机选择两个候选
            iTmp1 = randi(populationSize);
            iTmp2 = randi(populationSize);

            % 确保两个候选不同
            while iTmp2 == iTmp1 && populationSize > 1
                iTmp2 = randi(populationSize);
            end

            r = rand;

            % 根据问题类型比较适应度
            if strcmp(obj.problemType, "minimization")
                % 最小化问题：fitness越小越好
                if r < obj.explorationProb
                    % 选择更优者（更小）
                    if fitness(iTmp1) < fitness(iTmp2)
                        idx = iTmp1;
                    else
                        idx = iTmp2;
                    end
                else
                    % 选择较差者（更大，增加探索）
                    if fitness(iTmp1) < fitness(iTmp2)
                        idx = iTmp2;
                    else
                        idx = iTmp1;
                    end
                end
            else
                % 最大化问题：fitness越大越好
                if r < obj.explorationProb
                    % 选择更优者（更大）
                    if fitness(iTmp1) > fitness(iTmp2)
                        idx = iTmp1;
                    else
                        idx = iTmp2;
                    end
                else
                    % 选择较差者（更小，增加探索）
                    if fitness(iTmp1) > fitness(iTmp2)
                        idx = iTmp2;
                    else
                        idx = iTmp1;
                    end
                end
            end
        end

        function indices = binarySelectMultiple(obj, fitness, n)
            % binarySelectMultiple 二进制锦标赛选择多个个体
            %
            % 输入参数:
            %   fitness - 适应度向量 (N x 1)
            %   n - 需要选择的个体数量
            %
            % 输出参数:
            %   indices - 被选中个体的索引数组

            indices = zeros(n, 1);
            for i = 1:n
                indices(i) = obj.binarySelect(fitness);
            end
        end
    end
end
