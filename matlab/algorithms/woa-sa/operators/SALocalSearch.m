classdef SALocalSearch < handle
    % SALocalSearch 模拟退火局部搜索算子
    %
    % 用于二进制/特征选择问题的局部搜索。通过温度调度和
    % Metropolis准则接受或拒绝新解，具有跳出局部最优的能力。
    %
    % 算法原理:
    %   1. 生成邻居解 (通过变异)
    %   2. 若新解更优，直接接受
    %   3. 否则以概率 P = exp(-ΔE/T) 接受
    %   4. 温度按冷却率递减
    %
    % 参考文献:
    %   S. Kirkpatrick, C. D. Gelatt, M. P. Vecchi
    %   "Optimization by Simulated Annealing"
    %   Science, 1983
    %
    % 使用示例:
    %   sa = SALocalSearch(fobj, maxIter, initialTemp, coolingRate);
    %   [newSol, newFit] = sa.search(solution, fitness);
    %
    % 原始来源: Yarpiz (www.yarpiz.com)
    % 重构版本: 2.0.0
    % 日期: 2025

    properties
        objectiveFunction    % 目标函数句柄
        maxIterations int64 = 30      % 最大迭代次数
        maxSubIterations int64 = 10   % 每个温度的子迭代次数
        initialTemp double = 0.1      % 初始温度
        coolingRate double = 0.99     % 冷却率
        problemDim int64              % 问题维度
        mainMaxIterations int64       % 主算法最大迭代次数
    end

    methods
        function obj = SALocalSearch(varargin)
            % SALocalSearch 构造函数
            %
            % 输入参数 (键值对):
            %   'objectiveFunction' - 目标函数句柄 (必需)
            %   'maxIterations' - SA最大迭代次数 (默认: 30)
            %   'maxSubIterations' - 每温度子迭代次数 (默认: 10)
            %   'initialTemp' - 初始温度 (默认: 0.1)
            %   'coolingRate' - 冷却率 (默认: 0.99)
            %   'problemDim' - 问题维度 (必需)
            %   'mainMaxIterations' - 主算法最大迭代次数

            p = inputParser;
            addRequired(p, 'objectiveFunction', @(x) isa(x, 'function_handle'));
            addParameter(p, 'maxIterations', 30, @(x) x > 0);
            addParameter(p, 'maxSubIterations', 10, @(x) x > 0);
            addParameter(p, 'initialTemp', 0.1, @(x) x > 0);
            addParameter(p, 'coolingRate', 0.99, @(x) x > 0 && x <= 1);
            addParameter(p, 'problemDim', 0, @(x) x >= 0);
            addParameter(p, 'mainMaxIterations', 100, @(x) x > 0);

            parse(p, varargin{:});

            obj.objectiveFunction = p.Results.objectiveFunction;
            obj.maxIterations = p.Results.maxIterations;
            obj.maxSubIterations = p.Results.maxSubIterations;
            obj.initialTemp = p.Results.initialTemp;
            obj.coolingRate = p.Results.coolingRate;
            obj.problemDim = p.Results.problemDim;
            obj.mainMaxIterations = p.Results.mainMaxIterations;
        end

        function [bestSol, bestFit] = search(obj, currentSol, currentFit, currentMainIter)
            % search 执行模拟退火局部搜索
            %
            % 输入参数:
            %   currentSol - 当前解 (二进制向量)
            %   currentFit - 当前适应度
            %   currentMainIter - 主算法当前迭代次数 (用于自适应变异)
            %
            % 输出参数:
            %   bestSol - 搜索后的最优解
            %   bestFit - 最优适应度

            % 初始化
            bestSol = currentSol;
            bestFit = currentFit;
            tempSol = currentSol;
            tempFit = currentFit;

            % 初始化温度
            T = obj.initialTemp;

            % SA主循环
            for it = 1:obj.maxIterations
                for subIt = 1:obj.maxSubIterations
                    % 生成邻居解 (通过变异)
                    newSol = obj.generateNeighbor(tempSol, currentMainIter, subIt);

                    % 评估新解
                    newFit = obj.objectiveFunction(newSol);

                    % 接受准则
                    if newFit < tempFit
                        % 新解更优，直接接受
                        tempSol = newSol;
                        tempFit = newFit;

                        % 更新全局最优
                        if newFit < bestFit
                            bestSol = newSol;
                            bestFit = newFit;
                        end
                    else
                        % 计算接受概率
                        if tempFit ~= 0
                            delta = (newFit - tempFit) / tempFit;
                        else
                            delta = newFit - tempFit;
                        end
                        P = exp(-delta / T);

                        % 以概率P接受较差解
                        if rand <= P
                            tempSol = newSol;
                        end
                    end
                end

                % 更新温度
                T = obj.coolingRate * T;
            end
        end

        function neighbor = generateNeighbor(obj, solution, currentMainIter, subIter)
            % generateNeighbor 生成邻居解
            %
            % 输入参数:
            %   solution - 当前解
            %   currentMainIter - 主算法当前迭代次数
            %   subIter - 子迭代次数
            %
            % 输出参数:
            %   neighbor - 邻居解

            % 使用均匀变异生成邻居
            neighbor = UniformMutation.muteStatic(solution, ...
                currentMainIter + subIter, obj.mainMaxIterations);
        end
    end
end
