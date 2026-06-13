classdef TournamentSelection < SelectionOperator
    % TournamentSelection 锦标赛选择算子
    %
    % 通过多次二元锦标赛选择构建新种群。每次从种群中
    % 随机选择k个个体，保留最优者。
    %
    % 算法原理:
    %   1. 随机选择k个候选个体
    %   2. 比较适应度，选择最优者
    %   3. 重复n次得到n个被选中个体
    %
    % 使用示例:
    %   selector = TournamentSelection(3);
    %   indices = selector.select(population, fitness, n);
    %
    % 版本: 2.0.0
    % 日期: 2025

    properties
        tournamentSize int64 = 3  % 锦标赛大小
    end

    methods
        function obj = TournamentSelection(tournamentSize)
            % TournamentSelection 构造函数
            %
            % 输入参数:
            %   tournamentSize - 锦标赛大小 (默认: 3)

            if nargin > 0
                if tournamentSize < 2
                    error('TournamentSelection:InvalidParam', ...
                        'tournamentSize must be >= 2');
                end
                obj.tournamentSize = tournamentSize;
            end
        end

        function indices = select(obj, population, fitness, n)
            % select 执行锦标赛选择
            %
            % 输入参数:
            %   population - 种群矩阵 (N x Dim)
            %   fitness - 适应度向量 (N x 1)，值越小越优
            %   n - 需要选择的个体数量
            %
            % 输出参数:
            %   indices - 被选中个体的索引数组 (n x 1)

            popSize = size(population, 1);
            indices = zeros(n, 1);

            for i = 1:n
                % 随机选择tournamentSize个候选
                candidates = randperm(popSize, obj.tournamentSize);

                % 找出适应度最优者
                [~, bestIdx] = min(fitness(candidates));
                indices(i) = candidates(bestIdx);
            end
        end
    end
end
