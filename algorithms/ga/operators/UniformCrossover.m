classdef UniformCrossover < CrossoverOperator
    % UniformCrossover 均匀交叉算子
    %
    % 以固定概率从每个父代中选择基因，生成子代。
    % 相比单点/双点交叉，能更好地混合父代基因。
    %
    % 算法原理:
    %   对每个位置 j:
    %     - 若 rand < mixRate: offspring1(j) = parent1(j)
    %     - 否则: offspring1(j) = parent2(j)
    %
    % 使用示例:
    %   crossover = UniformCrossover(0.9, 0.5);
    %   [child1, child2] = crossover.cross(parent1, parent2);
    %
    % 版本: 2.0.0
    % 日期: 2025

    properties
        mixRate double = 0.5  % 从parent1取基因的概率
    end

    methods
        function obj = UniformCrossover(crossoverRate, mixRate)
            % UniformCrossover 构造函数
            %
            % 输入参数:
            %   crossoverRate - 交叉概率 (默认: 0.9)
            %   mixRate - 从parent1取基因的概率 (默认: 0.5)

            % 调用父类构造函数设置crossoverRate
            if nargin > 0
                obj = obj@CrossoverOperator(crossoverRate);
            else
                obj = obj@CrossoverOperator();
            end

            if nargin > 1
                if mixRate < 0 || mixRate > 1
                    error('UniformCrossover:InvalidParam', ...
                        'mixRate must be in [0, 1]');
                end
                obj.mixRate = mixRate;
            end
        end

        function [offspring1, offspring2] = cross(obj, parent1, parent2)
            % cross 执行均匀交叉
            %
            % 输入参数:
            %   parent1 - 第一个父代 (1 x Dim)
            %   parent2 - 第二个父代 (1 x Dim)
            %
            % 输出参数:
            %   offspring1 - 第一个子代 (1 x Dim)
            %   offspring2 - 第二个子代 (1 x Dim)

            % 生成混合掩码
            mask = rand(size(parent1)) < obj.mixRate;

            % 生成子代
            offspring1 = parent1;
            offspring1(~mask) = parent2(~mask);

            offspring2 = parent2;
            offspring2(~mask) = parent1(~mask);
        end
    end
end
