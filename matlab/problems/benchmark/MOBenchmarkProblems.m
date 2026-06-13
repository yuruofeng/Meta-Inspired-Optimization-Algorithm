classdef MOBenchmarkProblems < handle
    % MOBenchmarkProblems 多目标优化基准测试问题库
    %
    % 包含主流的多目标优化测试问题集，用于评估多目标元启发式算法性能。
    %
    % 问题分类:
    %   ZDT1-ZDT6:  Zitzler-Deb-Thiele 测试集 (2目标)
    %   DTLZ1-DTLZ7: Deb-Thiele-Laumanns-Zitzler 测试集 (可扩展目标)
    %
    % 使用示例:
    %   % 获取ZDT1问题
    %   problem = MOBenchmarkProblems.get('ZDT1');
    %   fitness = problem.evaluate(x);
    %   truePF = problem.getTrueParetoFront(100);
    %
    %   % 获取DTLZ1问题(3目标)
    %   problem = MOBenchmarkProblems.get('DTLZ1', 3);
    %
    % 参考文献:
    %   [1] Zitzler, E., Deb, K., & Thiele, L. (2000). Comparison of multiobjective 
    %       evolutionary algorithms: Empirical results. Evolutionary computation.
    %   [2] Deb, K., Thiele, L., Laumanns, M., & Zitzler, E. (2005). Scalable 
    %       test problems for evolutionary multiobjective optimization.
    %
    % 版本: 1.0.0
    % 日期: 2026
    % 作者: RUOFENG YU

    properties (Constant)
        ZDT_LIST = {'ZDT1', 'ZDT2', 'ZDT3', 'ZDT4', 'ZDT5', 'ZDT6'}
        DTLZ_LIST = {'DTLZ1', 'DTLZ2', 'DTLZ3', 'DTLZ4', 'DTLZ5', 'DTLZ6', 'DTLZ7'}
        ALL_LIST = {'ZDT1', 'ZDT2', 'ZDT3', 'ZDT4', 'ZDT5', 'ZDT6', ...
                    'DTLZ1', 'DTLZ2', 'DTLZ3', 'DTLZ4', 'DTLZ5', 'DTLZ6', 'DTLZ7'}
    end

    methods (Static)
        function problem = get(name, objCount, dim)
            % get 获取多目标测试问题
            %
            % 输入参数:
            %   name     - 问题名称 ('ZDT1'-'ZDT6', 'DTLZ1'-'DTLZ7')
            %   objCount - 目标数量 (可选, 默认2 for ZDT, 3 for DTLZ)
            %   dim      - 决策变量维度 (可选, 使用默认值)
            %
            % 输出参数:
            %   problem - 问题结构体, 包含:
            %             .evaluate   - 评估函数句柄
            %             .lb         - 下边界
            %             .ub         - 上边界
            %             .dim        - 维度
            %             .objCount   - 目标数量
            %             .name       - 问题名称
            %             .getTrueParetoFront(N) - 获取真实Pareto前沿
            
            arguments
                name char
                objCount (1,1) double = 2
                dim (1,1) double = []
            end

            switch name
                % ==================== ZDT系列 ====================
                case 'ZDT1'
                    problem = MOBenchmarkProblems.createZDT1(dim);
                case 'ZDT2'
                    problem = MOBenchmarkProblems.createZDT2(dim);
                case 'ZDT3'
                    problem = MOBenchmarkProblems.createZDT3(dim);
                case 'ZDT4'
                    problem = MOBenchmarkProblems.createZDT4(dim);
                case 'ZDT5'
                    problem = MOBenchmarkProblems.createZDT5();
                case 'ZDT6'
                    problem = MOBenchmarkProblems.createZDT6(dim);
                    
                % ==================== DTLZ系列 ====================
                case 'DTLZ1'
                    problem = MOBenchmarkProblems.createDTLZ1(objCount, dim);
                case 'DTLZ2'
                    problem = MOBenchmarkProblems.createDTLZ2(objCount, dim);
                case 'DTLZ3'
                    problem = MOBenchmarkProblems.createDTLZ3(objCount, dim);
                case 'DTLZ4'
                    problem = MOBenchmarkProblems.createDTLZ4(objCount, dim);
                case 'DTLZ5'
                    problem = MOBenchmarkProblems.createDTLZ5(objCount, dim);
                case 'DTLZ6'
                    problem = MOBenchmarkProblems.createDTLZ6(objCount, dim);
                case 'DTLZ7'
                    problem = MOBenchmarkProblems.createDTLZ7(objCount, dim);
                    
                otherwise
                    error('MOBenchmarkProblems:UnknownProblem', ...
                        'Unknown benchmark problem: %s', name);
            end
        end

        function list = list()
            % list 返回所有可用问题列表
            list = MOBenchmarkProblems.ALL_LIST;
        end

        function info = getInfo(name)
            % getInfo 获取问题详细信息
            problem = MOBenchmarkProblems.get(name);
            info = struct(...
                'name', name, ...
                'lowerBound', problem.lb, ...
                'upperBound', problem.ub, ...
                'dimension', problem.dim, ...
                'objCount', problem.objCount, ...
                'type', MOBenchmarkProblems.getProblemType(name) ...
            );
        end

        % ==================== ZDT系列问题 ====================

        function problem = createZDT1(dim)
            % ZDT1: 凸Pareto前沿
            % f1(x) = x1
            % f2(x) = g(x) * h(f1, g)
            % g(x) = 1 + 9*sum(x2:xm)/(m-1)
            % h(f1,g) = 1 - sqrt(f1/g)
            % Pareto前沿: f2 = 1 - sqrt(f1), f1 in [0,1]

            if nargin < 1 || isempty(dim)
                dim = 30;
            end

            problem.lb = 0;
            problem.ub = 1;
            problem.dim = dim;
            problem.objCount = 2;
            problem.name = 'ZDT1';
            
            problem.evaluate = @(x) MOBenchmarkProblems.evalZDT1(x);
            problem.getTrueParetoFront = @(N) MOBenchmarkProblems.getZDT1ParetoFront(N);
        end

        function f = evalZDT1(x)
            f1 = x(1);
            g = 1 + 9 * sum(x(2:end)) / (length(x) - 1);
            h = 1 - sqrt(f1 / g);
            f2 = g * h;
            f = [f1, f2];
        end

        function pf = getZDT1ParetoFront(N)
            f1 = linspace(0, 1, N)';
            f2 = 1 - sqrt(f1);
            pf = [f1, f2];
        end

        function problem = createZDT2(dim)
            % ZDT2: 非凸Pareto前沿
            % h(f1,g) = 1 - (f1/g)^2

            if nargin < 1 || isempty(dim)
                dim = 30;
            end

            problem.lb = 0;
            problem.ub = 1;
            problem.dim = dim;
            problem.objCount = 2;
            problem.name = 'ZDT2';
            
            problem.evaluate = @(x) MOBenchmarkProblems.evalZDT2(x);
            problem.getTrueParetoFront = @(N) MOBenchmarkProblems.getZDT2ParetoFront(N);
        end

        function f = evalZDT2(x)
            f1 = x(1);
            g = 1 + 9 * sum(x(2:end)) / (length(x) - 1);
            h = 1 - (f1 / g)^2;
            f2 = g * h;
            f = [f1, f2];
        end

        function pf = getZDT2ParetoFront(N)
            f1 = linspace(0, 1, N)';
            f2 = 1 - f1.^2;
            pf = [f1, f2];
        end

        function problem = createZDT3(dim)
            % ZDT3: 不连续Pareto前沿
            % h(f1,g) = 1 - sqrt(f1/g) - (f1/g)*sin(10*pi*f1)

            if nargin < 1 || isempty(dim)
                dim = 30;
            end

            problem.lb = 0;
            problem.ub = 1;
            problem.dim = dim;
            problem.objCount = 2;
            problem.name = 'ZDT3';
            
            problem.evaluate = @(x) MOBenchmarkProblems.evalZDT3(x);
            problem.getTrueParetoFront = @(N) MOBenchmarkProblems.getZDT3ParetoFront(N);
        end

        function f = evalZDT3(x)
            f1 = x(1);
            g = 1 + 9 * sum(x(2:end)) / (length(x) - 1);
            h = 1 - sqrt(f1 / g) - (f1 / g) * sin(10 * pi * f1);
            f2 = g * h;
            f = [f1, f2];
        end

        function pf = getZDT3ParetoFront(N)
            f1 = linspace(0, 0.852, N)';
            f2 = 1 - sqrt(f1) - f1 .* sin(10 * pi * f1);
            valid = f2 >= -0.1;
            pf = [f1(valid), f2(valid)];
        end

        function problem = createZDT4(dim)
            % ZDT4: 多模态问题，有21^9个局部最优
            % x1 in [0,1], xi in [-5,5] for i>1

            if nargin < 1 || isempty(dim)
                dim = 10;
            end

            problem.lb = [0, -5*ones(1, dim-1)];
            problem.ub = [1, 5*ones(1, dim-1)];
            problem.dim = dim;
            problem.objCount = 2;
            problem.name = 'ZDT4';
            
            problem.evaluate = @(x) MOBenchmarkProblems.evalZDT4(x);
            problem.getTrueParetoFront = @(N) MOBenchmarkProblems.getZDT1ParetoFront(N);
        end

        function f = evalZDT4(x)
            f1 = x(1);
            g = 1 + 10 * (length(x) - 1) + sum(x(2:end).^2 - 10 * cos(4 * pi * x(2:end)));
            h = 1 - sqrt(f1 / g);
            f2 = g * h;
            f = [f1, f2];
        end

        function problem = createZDT5()
            % ZDT5: 二进制编码问题
            % 这里提供简化版本

            problem.lb = 0;
            problem.ub = 1;
            problem.dim = 30;
            problem.objCount = 2;
            problem.name = 'ZDT5';
            
            problem.evaluate = @(x) MOBenchmarkProblems.evalZDT5(x);
            problem.getTrueParetoFront = @(N) MOBenchmarkProblems.getZDT5ParetoFront(N);
        end

        function f = evalZDT5(x)
            f1 = 1 + sum(x(1:11));
            g = sum(x(12:end));
            h = 1 / f1;
            f2 = g * h;
            f = [f1, f2];
        end

        function pf = getZDT5ParetoFront(N)
            f1 = linspace(1, 12, N)';
            f2 = 1 ./ f1;
            pf = [f1, f2];
        end

        function problem = createZDT6(dim)
            % ZDT6: 非均匀分布的Pareto前沿
            % f1 = 1 - exp(-4*x1) * sin(6*pi*x1)^6
            % g = 1 + 9 * (sum(x2:xm)/(m-1))^0.25

            if nargin < 1 || isempty(dim)
                dim = 10;
            end

            problem.lb = 0;
            problem.ub = 1;
            problem.dim = dim;
            problem.objCount = 2;
            problem.name = 'ZDT6';
            
            problem.evaluate = @(x) MOBenchmarkProblems.evalZDT6(x);
            problem.getTrueParetoFront = @(N) MOBenchmarkProblems.getZDT6ParetoFront(N);
        end

        function f = evalZDT6(x)
            f1 = 1 - exp(-4 * x(1)) * sin(6 * pi * x(1))^6;
            g = 1 + 9 * (sum(x(2:end)) / (length(x) - 1))^0.25;
            h = 1 - (f1 / g)^2;
            f2 = g * h;
            f = [f1, f2];
        end

        function pf = getZDT6ParetoFront(N)
            f1 = linspace(0.281, 1, N)';
            f2 = 1 - f1.^2;
            pf = [f1, f2];
        end

        % ==================== DTLZ系列问题 ====================

        function problem = createDTLZ1(objCount, dim)
            % DTLZ1: 线性Pareto前沿
            % 最小值: f = 0.5*x1*...*xk-1*(1+g)
            % g = 100*(|xk| + sum((xi-0.5)^2 - cos(20*pi*(xi-0.5))))

            if nargin < 1 || isempty(objCount)
                objCount = 3;
            end
            if nargin < 2 || isempty(dim)
                dim = objCount + 4;
            end

            problem.lb = 0;
            problem.ub = 1;
            problem.dim = dim;
            problem.objCount = objCount;
            problem.name = 'DTLZ1';
            
            problem.evaluate = @(x) MOBenchmarkProblems.evalDTLZ1(x, objCount);
            problem.getTrueParetoFront = @(N) MOBenchmarkProblems.getDTLZ1ParetoFront(N, objCount);
        end

        function f = evalDTLZ1(x, m)
            k = length(x) - m + 1;
            g = 100 * (k + sum((x(m:end) - 0.5).^2 - cos(20 * pi * (x(m:end) - 0.5))));
            
            f = zeros(1, m);
            for i = 1:m
                if i == 1
                    f(i) = 0.5 * prod(x(1:m-1)) * (1 + g);
                elseif i == m
                    f(i) = 0.5 * (1 - x(1)) * (1 + g);
                else
                    f(i) = 0.5 * prod(x(1:m-i)) * (1 - x(m-i+1)) * (1 + g);
                end
            end
        end

        function pf = getDTLZ1ParetoFront(N, m)
            if m == 2
                f1 = linspace(0, 0.5, N)';
                f2 = 0.5 - f1;
                pf = [f1, f2];
            elseif m == 3
                [f1, f2] = meshgrid(linspace(0, 0.5, ceil(sqrt(N))));
                f3 = 0.5 - f1 - f2;
                valid = f3 >= 0;
                pf = [f1(valid), f2(valid), f3(valid)];
            else
                error('DTLZ1 Pareto front for m > 3 not implemented');
            end
        end

        function problem = createDTLZ2(objCount, dim)
            % DTLZ2: 球面Pareto前沿

            if nargin < 1 || isempty(objCount)
                objCount = 3;
            end
            if nargin < 2 || isempty(dim)
                dim = objCount + 9;
            end

            problem.lb = 0;
            problem.ub = 1;
            problem.dim = dim;
            problem.objCount = objCount;
            problem.name = 'DTLZ2';
            
            problem.evaluate = @(x) MOBenchmarkProblems.evalDTLZ2(x, objCount);
            problem.getTrueParetoFront = @(N) MOBenchmarkProblems.getDTLZ2ParetoFront(N, objCount);
        end

        function f = evalDTLZ2(x, m)
            k = length(x) - m + 1;
            g = sum((x(m:end) - 0.5).^2);
            
            f = zeros(1, m);
            for i = 1:m
                if i == 1
                    f(i) = (1 + g) * prod(cos(x(1:m-1) * pi / 2));
                elseif i == m
                    f(i) = (1 + g) * sin(x(1) * pi / 2);
                else
                    f(i) = (1 + g) * prod(cos(x(1:m-i) * pi / 2)) * sin(x(m-i+1) * pi / 2);
                end
            end
        end

        function pf = getDTLZ2ParetoFront(N, m)
            if m == 2
                theta = linspace(0, pi/2, N)';
                f1 = cos(theta);
                f2 = sin(theta);
                pf = [f1, f2];
            elseif m == 3
                [theta, phi] = meshgrid(linspace(0, pi/2, ceil(sqrt(N))));
                f1 = cos(theta) .* cos(phi);
                f2 = cos(theta) .* sin(phi);
                f3 = sin(theta);
                pf = [f1(:), f2(:), f3(:)];
            else
                error('DTLZ2 Pareto front for m > 3 not implemented');
            end
        end

        function problem = createDTLZ3(objCount, dim)
            % DTLZ3: 多模态球面前沿

            if nargin < 1 || isempty(objCount)
                objCount = 3;
            end
            if nargin < 2 || isempty(dim)
                dim = objCount + 9;
            end

            problem.lb = 0;
            problem.ub = 1;
            problem.dim = dim;
            problem.objCount = objCount;
            problem.name = 'DTLZ3';
            
            problem.evaluate = @(x) MOBenchmarkProblems.evalDTLZ3(x, objCount);
            problem.getTrueParetoFront = @(N) MOBenchmarkProblems.getDTLZ2ParetoFront(N, objCount);
        end

        function f = evalDTLZ3(x, m)
            k = length(x) - m + 1;
            g = 100 * (k + sum((x(m:end) - 0.5).^2 - cos(20 * pi * (x(m:end) - 0.5))));
            
            f = zeros(1, m);
            for i = 1:m
                if i == 1
                    f(i) = (1 + g) * prod(cos(x(1:m-1) * pi / 2));
                elseif i == m
                    f(i) = (1 + g) * sin(x(1) * pi / 2);
                else
                    f(i) = (1 + g) * prod(cos(x(1:m-i) * pi / 2)) * sin(x(m-i+1) * pi / 2);
                end
            end
        end

        function problem = createDTLZ4(objCount, dim)
            % DTLZ4: 偏置球面前沿

            if nargin < 1 || isempty(objCount)
                objCount = 3;
            end
            if nargin < 2 || isempty(dim)
                dim = objCount + 9;
            end

            problem.lb = 0;
            problem.ub = 1;
            problem.dim = dim;
            problem.objCount = objCount;
            problem.name = 'DTLZ4';
            
            problem.evaluate = @(x) MOBenchmarkProblems.evalDTLZ4(x, objCount);
            problem.getTrueParetoFront = @(N) MOBenchmarkProblems.getDTLZ2ParetoFront(N, objCount);
        end

        function f = evalDTLZ4(x, m)
            alpha = 100;
            k = length(x) - m + 1;
            g = sum((x(m:end) - 0.5).^2);
            
            f = zeros(1, m);
            for i = 1:m
                if i == 1
                    f(i) = (1 + g) * prod(cos(x(1:m-1).^alpha * pi / 2));
                elseif i == m
                    f(i) = (1 + g) * sin(x(1).^alpha * pi / 2);
                else
                    f(i) = (1 + g) * prod(cos(x(1:m-i).^alpha * pi / 2)) * sin(x(m-i+1).^alpha * pi / 2);
                end
            end
        end

        function problem = createDTLZ5(objCount, dim)
            % DTLZ5: 退化Pareto前沿

            if nargin < 1 || isempty(objCount)
                objCount = 3;
            end
            if nargin < 2 || isempty(dim)
                dim = objCount + 9;
            end

            problem.lb = 0;
            problem.ub = 1;
            problem.dim = dim;
            problem.objCount = objCount;
            problem.name = 'DTLZ5';
            
            problem.evaluate = @(x) MOBenchmarkProblems.evalDTLZ5(x, objCount);
            problem.getTrueParetoFront = @(N) MOBenchmarkProblems.getDTLZ5ParetoFront(N, objCount);
        end

        function f = evalDTLZ5(x, m)
            k = length(x) - m + 1;
            g = sum((x(m:end) - 0.5).^2);
            
            theta = zeros(1, m-1);
            theta(1) = x(1) * pi / 2;
            for i = 2:m-1
                theta(i) = (1 + 2 * g * x(i)) / (4 * (1 + g)) * pi;
            end
            
            f = zeros(1, m);
            for i = 1:m
                if i == 1
                    f(i) = (1 + g) * prod(cos(theta));
                elseif i == m
                    f(i) = (1 + g) * sin(theta(1));
                else
                    f(i) = (1 + g) * prod(cos(theta(1:m-i))) * sin(theta(m-i+1));
                end
            end
        end

        function pf = getDTLZ5ParetoFront(N, m)
            if m == 2
                theta = linspace(0, pi/2, N)';
                f1 = cos(theta);
                f2 = sin(theta);
                pf = [f1, f2];
            elseif m == 3
                theta1 = pi/2;
                theta2 = linspace(0, pi/2, N)';
                f1 = cos(theta2);
                f2 = sin(theta2) .* cos(theta1);
                f3 = sin(theta2) .* sin(theta1);
                pf = [f1, f2, f3];
            else
                error('DTLZ5 Pareto front for m > 3 not implemented');
            end
        end

        function problem = createDTLZ6(objCount, dim)
            % DTLZ6: 更强的偏置

            if nargin < 1 || isempty(objCount)
                objCount = 3;
            end
            if nargin < 2 || isempty(dim)
                dim = objCount + 9;
            end

            problem.lb = 0;
            problem.ub = 1;
            problem.dim = dim;
            problem.objCount = objCount;
            problem.name = 'DTLZ6';
            
            problem.evaluate = @(x) MOBenchmarkProblems.evalDTLZ6(x, objCount);
            problem.getTrueParetoFront = @(N) MOBenchmarkProblems.getDTLZ5ParetoFront(N, objCount);
        end

        function f = evalDTLZ6(x, m)
            k = length(x) - m + 1;
            g = sum(x(m:end).^0.1);
            
            theta = zeros(1, m-1);
            theta(1) = x(1) * pi / 2;
            for i = 2:m-1
                theta(i) = (1 + 2 * g * x(i)) / (4 * (1 + g)) * pi;
            end
            
            f = zeros(1, m);
            for i = 1:m
                if i == 1
                    f(i) = (1 + g) * prod(cos(theta));
                elseif i == m
                    f(i) = (1 + g) * sin(theta(1));
                else
                    f(i) = (1 + g) * prod(cos(theta(1:m-i))) * sin(theta(m-i+1));
                end
            end
        end

        function problem = createDTLZ7(objCount, dim)
            % DTLZ7: 不连续Pareto前沿

            if nargin < 1 || isempty(objCount)
                objCount = 3;
            end
            if nargin < 2 || isempty(dim)
                dim = objCount + 19;
            end

            problem.lb = 0;
            problem.ub = 1;
            problem.dim = dim;
            problem.objCount = objCount;
            problem.name = 'DTLZ7';
            
            problem.evaluate = @(x) MOBenchmarkProblems.evalDTLZ7(x, objCount);
            problem.getTrueParetoFront = @(N) MOBenchmarkProblems.getDTLZ7ParetoFront(N, objCount);
        end

        function f = evalDTLZ7(x, m)
            k = length(x) - m + 1;
            g = 1 + 9/k * sum(x(m:end));
            
            f = zeros(1, m);
            for i = 1:m-1
                f(i) = x(i);
            end
            
            h = 0;
            for i = 1:m-1
                h = h + f(i)/(1 + g) * (1 + sin(3 * pi * f(i)));
            end
            h = m - h;
            
            f(m) = (1 + g) * h;
        end

        function pf = getDTLZ7ParetoFront(N, m)
            if m == 2
                f1 = linspace(0, 1, N)';
                h = 2 - (f1/(1+0)) .* (1 + sin(3*pi*f1));
                f2 = (1 + 0) * h;
                pf = [f1, f2];
            elseif m == 3
                f1 = linspace(0, 1, ceil(sqrt(N)))';
                f2 = linspace(0, 1, ceil(sqrt(N)))';
                [F1, F2] = meshgrid(f1, f2);
                h = 3 - (F1/(1+0)).*(1+sin(3*pi*F1)) - (F2/(1+0)).*(1+sin(3*pi*F2));
                F3 = (1 + 0) * h;
                valid = F3 >= 0 & F3 <= 6;
                pf = [F1(valid), F2(valid), F3(valid)];
            else
                error('DTLZ7 Pareto front for m > 3 not implemented');
            end
        end
    end

    methods (Static, Access = private)
        function type = getProblemType(name)
            if any(strcmp(name, MOBenchmarkProblems.ZDT_LIST))
                type = 'ZDT';
            elseif any(strcmp(name, MOBenchmarkProblems.DTLZ_LIST))
                type = 'DTLZ';
            else
                type = 'Unknown';
            end
        end
    end
end
