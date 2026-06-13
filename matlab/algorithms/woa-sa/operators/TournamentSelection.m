classdef TournamentSelection < handle
    % TournamentSelection 二元锦标赛选择算子
    %
    % 用于二进制/特征选择问题的选择操作。从两个随机候选个体中
    % 选择适应度较优者，具有一定的随机性以保持多样性。
    %
    % 算法原理:
    %   1. 随机选择两个候选个体 iTmp1, iTmp2
    %   2. 生成随机数 r
    %   3. 若 r < tournamentParameter: 选择适应度更优者
    %   4. 否则: 选择适应度较差者（探索）
    %
    % 参考文献:
    %   M. Mafarja and S. Mirjalili
    %   "Hybrid Whale Optimization Algorithm with Simulated Annealing
    %    for Feature Selection"
    %   Neurocomputing, 2017
    %
    % 使用示例:
    %   selector = TournamentSelection(0.7);
    %   idx = selector.select(fitness);
    %
    % 原始作者: Majdi Mafarja, Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2025

    properties
        tournamentParameter double = 0.5  % 锦标赛选择压力参数
    end

    methods
        function obj = TournamentSelection(param)
            % TournamentSelection 构造函数
            %
            % 输入参数:
            %   param - 锦标赛参数 (默认: 0.5)
            %           较高的值倾向于选择更优个体
            %           值范围: [0, 1]

            if nargin > 0
                if param < 0 || param > 1
                    error('TournamentSelection:InvalidParam', ...
                        'tournamentParameter must be in [0, 1]');
                end
                obj.tournamentParameter = param;
            end
        end

        function idx = select(obj, fitness)
            % select 执行锦标赛选择
            %
            % 输入参数:
            %   fitness - 适应度向量 (N x 1)，值越大表示越优
            %
            % 输出参数:
            %   idx - 被选中个体的索引
            %
            % 注意: 此实现假设最大化问题（适应度越大越好）
            %       对于最小化问题，应传入 1./fitness 或负值

            populationSize = size(fitness, 1);

            % 随机选择两个候选
            iTmp1 = 1 + floor(rand * populationSize);
            iTmp2 = 1 + floor(rand * populationSize);

            % 确保索引有效
            iTmp1 = min(max(iTmp1, 1), populationSize);
            iTmp2 = min(max(iTmp2, 1), populationSize);

            r = rand;

            if r < obj.tournamentParameter
                % 选择更优者
                if fitness(iTmp1) > fitness(iTmp2)
                    idx = iTmp1;
                else
                    idx = iTmp2;
                end
            else
                % 选择较差者（增加探索）
                if fitness(iTmp1) > fitness(iTmp2)
                    idx = iTmp2;
                else
                    idx = iTmp1;
                end
            end
        end

        function indices = selectMultiple(obj, fitness, n)
            % selectMultiple 选择多个个体
            %
            % 输入参数:
            %   fitness - 适应度向量 (N x 1)
            %   n - 需要选择的个体数量
            %
            % 输出参数:
            %   indices - 被选中个体的索引数组

            indices = zeros(n, 1);
            for i = 1:n
                indices(i) = obj.select(fitness);
            end
        end
    end
end
