classdef UniformCrossover < handle
    % UniformCrossover 均匀交叉算子
    %
    % 用于二进制/特征选择问题的交叉操作。以0.5的概率从
    % 每个父代中选择基因，生成子代。
    %
    % 算法原理:
    %   对每个位置 j:
    %     - 若 rand < 0.5: offspring(j) = parent1(j)
    %     - 否则: offspring(j) = parent2(j)
    %
    % 参考文献:
    %   M. Mafarja and S. Mirjalili
    %   "Hybrid Whale Optimization Algorithm with Simulated Annealing
    %    for Feature Selection"
    %   Neurocomputing, 2017
    %
    % 使用示例:
    %   crossover = UniformCrossover();
    %   offspring = crossover.cross(parent1, parent2);
    %
    % 原始作者: Majdi Mafarja, Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2025

    properties
        crossoverRate double = 0.5  % 从parent1取基因的概率
    end

    methods
        function obj = UniformCrossover(rate)
            % UniformCrossover 构造函数
            %
            % 输入参数:
            %   rate - 从parent1取基因的概率 (默认: 0.5)
            %          值范围: [0, 1]

            if nargin > 0
                if rate < 0 || rate > 1
                    error('UniformCrossover:InvalidParam', ...
                        'crossoverRate must be in [0, 1]');
                end
                obj.crossoverRate = rate;
            end
        end

        function offspring = cross(obj, parent1, parent2)
            % cross 执行均匀交叉
            %
            % 输入参数:
            %   parent1 - 第一个父代解向量
            %   parent2 - 第二个父代解向量
            %
            % 输出参数:
            %   offspring - 生成的子代解向量

            r = rand(size(parent1)) < obj.crossoverRate;
            offspring = parent1;
            offspring(~r) = parent2(~r);
        end

        function [offspring1, offspring2] = crossTwo(obj, parent1, parent2)
            % crossTwo 生成两个子代
            %
            % 输入参数:
            %   parent1 - 第一个父代解向量
            %   parent2 - 第二个父代解向量
            %
            % 输出参数:
            %   offspring1 - 第一个子代
            %   offspring2 - 第二个子代

            r = rand(size(parent1)) < obj.crossoverRate;

            offspring1 = parent1;
            offspring1(~r) = parent2(~r);

            offspring2 = parent2;
            offspring2(~r) = parent1(~r);
        end
    end

    methods (Static)
        function offspring = crossStatic(parent1, parent2)
            % crossStatic 静态方法版本的交叉操作
            %
            % 输入参数:
            %   parent1 - 第一个父代解向量
            %   parent2 - 第二个父代解向量
            %
            % 输出参数:
            %   offspring - 生成的子代解向量

            r = rand(size(parent1)) < 0.5;
            offspring = parent1;
            offspring(~r) = parent2(~r);
        end
    end
end
