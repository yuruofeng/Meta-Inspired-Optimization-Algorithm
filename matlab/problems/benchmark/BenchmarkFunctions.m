classdef BenchmarkFunctions < handle
    % BenchmarkFunctions 统一基准测试函数库
    %
    % 包含23个国际通用基准测试函数，用于评估元启发式算法性能。
    % 符合 metaheuristic_spec.md §6.2 规范。
    %
    % 函数分类:
    %   F1-F7:   单峰函数 (Unimodal)
    %   F8-F13:  多峰函数 (Multimodal)
    %   F14-F23: 固定维度多峰函数 (Fixed-dimension Multimodal)
    %
    % 使用示例:
    %   % 获取函数信息
    %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');
    %
    %   % 评估解
    %   x = rand(1, dim) .* (ub - lb) + lb;
    %   fitness = fobj(x);
    %
    %   % 获取所有函数列表
    %   list = BenchmarkFunctions.list();
    %
    % 合并来源:
    %   - ALO/ALO/Get_Functions_details.m (365行)
    %   - GWO/GWO/Get_Functions_details.m (365行)
    %   - I-GWO/I-GWO/Get_Functions_details.m (365行)
    %
    % 原始作者: Seyedali Mirjalili
    % 整合版本: 2.0.0
    % 日期: 2025
    % 作者：RUOFENG YU

    properties (Constant)
        FUNCTION_LIST = {'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', ...
                         'F8', 'F9', 'F10', 'F11', 'F12', 'F13', ...
                         'F14', 'F15', 'F16', 'F17', 'F18', 'F19', ...
                         'F20', 'F21', 'F22', 'F23'}
    end

    methods (Static)
        function [lb, ub, dim, fobj] = get(F)
            % get 获取基准函数配置
            %
            % 输入参数:
            %   F - 函数名称 (字符串, 'F1'-'F23')
            %
            % 输出参数:
            %   lb   - 下边界
            %   ub   - 上边界
            %   dim  - 维度
            %   fobj - 函数句柄
            %
            % 示例:
            %   [lb, ub, dim, fobj] = BenchmarkFunctions.get('F1');

            switch F
                % ============= F1-F7: 单峰函数 =============
                case 'F1'
                    fobj = @BenchmarkFunctions.F1;
                    lb = -100; ub = 100; dim = 30;

                case 'F2'
                    fobj = @BenchmarkFunctions.F2;
                    lb = -10; ub = 10; dim = 30;

                case 'F3'
                    fobj = @BenchmarkFunctions.F3;
                    lb = -100; ub = 100; dim = 30;

                case 'F4'
                    fobj = @BenchmarkFunctions.F4;
                    lb = -100; ub = 100; dim = 30;

                case 'F5'
                    fobj = @BenchmarkFunctions.F5;
                    lb = -30; ub = 30; dim = 30;

                case 'F6'
                    fobj = @BenchmarkFunctions.F6;
                    lb = -100; ub = 100; dim = 30;

                case 'F7'
                    fobj = @BenchmarkFunctions.F7;
                    lb = -1.28; ub = 1.28; dim = 30;

                % ============= F8-F13: 多峰函数 =============
                case 'F8'
                    fobj = @BenchmarkFunctions.F8;
                    lb = -500; ub = 500; dim = 30;

                case 'F9'
                    fobj = @BenchmarkFunctions.F9;
                    lb = -5.12; ub = 5.12; dim = 30;

                case 'F10'
                    fobj = @BenchmarkFunctions.F10;
                    lb = -32; ub = 32; dim = 30;

                case 'F11'
                    fobj = @BenchmarkFunctions.F11;
                    lb = -600; ub = 600; dim = 30;

                case 'F12'
                    fobj = @BenchmarkFunctions.F12;
                    lb = -50; ub = 50; dim = 30;

                case 'F13'
                    fobj = @BenchmarkFunctions.F13;
                    lb = -50; ub = 50; dim = 30;

                % ============= F14-F23: 固定维度函数 =============
                case 'F14'
                    fobj = @BenchmarkFunctions.F14;
                    lb = -65.536; ub = 65.536; dim = 2;

                case 'F15'
                    fobj = @BenchmarkFunctions.F15;
                    lb = -5; ub = 5; dim = 4;

                case 'F16'
                    fobj = @BenchmarkFunctions.F16;
                    lb = -5; ub = 5; dim = 2;

                case 'F17'
                    fobj = @BenchmarkFunctions.F17;
                    lb = [-5, 0]; ub = [10, 15]; dim = 2;

                case 'F18'
                    fobj = @BenchmarkFunctions.F18;
                    lb = -5; ub = 5; dim = 2;

                case 'F19'
                    fobj = @BenchmarkFunctions.F19;
                    lb = 0; ub = 1; dim = 3;

                case 'F20'
                    fobj = @BenchmarkFunctions.F20;
                    lb = 0; ub = 1; dim = 6;

                case 'F21'
                    fobj = @BenchmarkFunctions.F21;
                    lb = 0; ub = 10; dim = 4;

                case 'F22'
                    fobj = @BenchmarkFunctions.F22;
                    lb = 0; ub = 10; dim = 4;

                case 'F23'
                    fobj = @BenchmarkFunctions.F23;
                    lb = 0; ub = 10; dim = 4;

                otherwise
                    error('BenchmarkFunctions:UnknownFunction', ...
                        'Unknown benchmark function: %s', F);
            end
        end

        function list = list()
            % list 返回所有可用函数列表
            %
            % 输出参数:
            %   list - 函数名称元胞数组
            %
            % 示例:
            %   functions = BenchmarkFunctions.list();

            list = BenchmarkFunctions.FUNCTION_LIST;
        end

        function info = getInfo(F)
            % getInfo 获取函数详细信息
            %
            % 输入参数:
            %   F - 函数名称
            %
            % 输出参数:
            %   info - 包含名称、类型、最优值等信息的结构体

            [lb, ub, dim, ~] = BenchmarkFunctions.get(F);

            info = struct(...
                'name', F, ...
                'lowerBound', lb, ...
                'upperBound', ub, ...
                'dimension', dim, ...
                'type', BenchmarkFunctions.getFunctionType(F), ...
                'optimalValue', BenchmarkFunctions.getOptimalValue(F) ...
            );
        end

        % ==================== F1-F7: 单峰函数 ====================

        function o = F1(x)
            % F1 Sphere函数
            % 最优值: 0 (在 x = [0,0,...,0])
            o = sum(x.^2);
        end

        function o = F2(x)
            % F2 Schwefel 2.22函数
            % 最优值: 0
            o = sum(abs(x)) + prod(abs(x));
        end

        function o = F3(x)
            % F3 Schwefel 1.2函数
            % 最优值: 0
            dim = size(x, 2);
            o = 0;
            for i = 1:dim
                o = o + sum(x(1:i))^2;
            end
        end

        function o = F4(x)
            % F4 Schwefel 2.21函数
            % 最优值: 0
            o = max(abs(x));
        end

        function o = F5(x)
            % F5 Rosenbrock函数
            % 最优值: 0
            dim = size(x, 2);
            o = sum(100*(x(2:dim)-(x(1:dim-1).^2)).^2+(x(1:dim-1)-1).^2);
        end

        function o = F6(x)
            % F6 Step函数
            % 最优值: 0
            o = sum(floor((x+.5)).^2);
        end

        function o = F7(x)
            % F7 Quartic函数 (带噪声)
            % 最优值: 0
            dim = size(x, 2);
            o = sum((1:dim) .* (x.^4)) + rand();
        end

        % ==================== F8-F13: 多峰函数 ====================

        function o = F8(x)
            % F8 Schwefel函数
            % 最优值: -418.9829 * dim
            o = sum(-x .* sin(sqrt(abs(x))));
        end

        function o = F9(x)
            % F9 Rastrigin函数
            % 最优值: 0
            dim = size(x, 2);
            o = sum(x.^2 - 10*cos(2*pi.*x)) + 10*dim;
        end

        function o = F10(x)
            % F10 Ackley函数
            % 最优值: 0
            dim = size(x, 2);
            o = -20*exp(-.2*sqrt(sum(x.^2)/dim)) - ...
                exp(sum(cos(2*pi.*x))/dim) + 20 + exp(1);
        end

        function o = F11(x)
            % F11 Griewank函数
            % 最优值: 0
            dim = size(x, 2);
            o = sum(x.^2)/4000 - prod(cos(x./sqrt(1:dim))) + 1;
        end

        function o = F12(x)
            % F12 Penalized函数1
            % 最优值: 0
            dim = size(x, 2);
            o = (pi/dim) * (10*((sin(pi*(1+(x(1)+1)/4)))^2) + ...
                sum((((x(1:dim-1)+1)./4).^2) .* ...
                (1+10*((sin(pi*(1+(x(2:dim)+1)/4)))).^2)) + ...
                ((x(dim)+1)/4)^2) + sum(BenchmarkFunctions.Ufun(x,10,100,4));
        end

        function o = F13(x)
            % F13 Penalized函数2
            % 最优值: 0
            dim = size(x, 2);
            o = .1*((sin(3*pi*x(1)))^2 + sum((x(1:dim-1)-1).^2 .* ...
                (1+(sin(3.*pi.*x(2:dim))).^2)) + ...
                ((x(dim)-1))^2*(1+(sin(2*pi*x(dim)))^2)) + ...
                sum(BenchmarkFunctions.Ufun(x,5,100,4));
        end

        % ==================== F14-F23: 固定维度函数 ====================

        function o = F14(x)
            % F14 Shekel's Foxholes函数
            % 最优值: 0.998 (approx)
            aS = [-32 -16 0 16 32 -32 -16 0 16 32 -32 -16 0 16 32 -32 -16 0 16 32 -32 -16 0 16 32; ...
                  -32 -32 -32 -32 -32 -16 -16 -16 -16 -16 0 0 0 0 0 16 16 16 16 16 32 32 32 32 32];
            bS = [0.1 0.2 0.2 0.4 0.4 0.6 0.3 0.7 0.5 0.5 ...
                  0.3 0.7 0.6 0.6 0.5 0.4 0.4 0.3 0.2 0.2 ...
                  0.1 0.1 0.2 0.4 0.4];
            bS = bS';
            aS = aS';
            o = 1/(1/500 + sum(1./((1:25)' + (x(1) - aS(:,1)).^6 + ...
                (x(2) - aS(:,2)).^6)));
        end

        function o = F15(x)
            % F15 Kowalik函数
            % 最优值: 0.0003075 (approx)
            aK = [0.1957 0.1947 0.1735 0.16 0.0844 0.0627 0.0456 0.0342 0.0323 0.0235 0.0246];
            bK = [0.25 0.5 1 2 4 6 8 10 12 14 16];
            bK = 1./bK;
            o = sum((aK - ((x(1)*(bK.^2+x(2)*bK))./(bK.^2+x(3)*bK+x(4)))).^2);
        end

        function o = F16(x)
            % F16 Six-Hump Camel Back函数
            % 最优值: -1.0316285 (approx)
            o = 4*x(1)^2-2.1*x(1)^4+x(1)^6/3+x(1)*x(2)-4*x(2)^2+4*x(2)^4;
        end

        function o = F17(x)
            % F17 Branin函数
            % 最优值: 0.397887 (approx)
            o = (x(2)-5.1/(4*pi^2)*x(1)^2+5/pi*x(1)-6)^2 + ...
                10*(1-1/(8*pi))*cos(x(1))+10;
        end

        function o = F18(x)
            % F18 Goldstein-Price函数
            % 最优值: 3
            o = (1+(x(1)+x(2)+1)^2*(19-14*x(1)+3*x(1)^2-14*x(2)+6*x(1)*x(2)+3*x(2)^2)) * ...
                (30+(2*x(1)-3*x(2))^2*(18-32*x(1)+12*x(1)^2+48*x(2)-36*x(1)*x(2)+27*x(2)^2));
        end

        function o = F19(x)
            % F19 Hartman 3函数
            % 最优值: -3.86 (approx)
            aH = [3 10 30; 0.1 10 35; 3 10 30; 0.1 10 35];
            cH = [1 1.2 3 3.2];
            pH = [0.3689 0.117 0.2673; 0.4699 0.4387 0.747; ...
                  0.1091 0.8732 0.5547; 0.03815 0.5743 0.8828];
            o = 0;
            for i = 1:4
                o = o - cH(i)*exp(-(sum(aH(i,:).*(x-pH(i,:)).^2)));
            end
        end

        function o = F20(x)
            % F20 Hartman 6函数
            % 最优值: -3.32 (approx)
            aH = [10 3 17 3.5 1.7 8; 0.05 10 17 0.1 8 14; ...
                  3 3.5 1.7 10 17 8; 17 8 0.05 10 0.1 14];
            cH = [1 1.2 3 3.2];
            pH = [0.1312 0.1696 0.5569 0.0124 0.8283 0.5886; ...
                  0.2329 0.4135 0.8307 0.3736 0.1004 0.9991; ...
                  0.2348 0.1451 0.3522 0.2883 0.3047 0.665; ...
                  0.4047 0.8828 0.8732 0.5743 0.1091 0.0381];
            o = 0;
            for i = 1:4
                o = o - cH(i)*exp(-(sum(aH(i,:).*(x-pH(i,:)).^2)));
            end
        end

        function o = F21(x)
            % F21 Shekel 5函数
            % 最优值: -10.1532 (approx)
            aSH = [4 4 4 4; 1 1 1 1; 8 8 8 8; 6 6 6 6; 3 7 3 7; ...
                   2 9 2 9; 5 5 3 3; 8 1 8 1; 6 2 6 2; 7 3.6 7 3.6];
            cSH = [0.1 0.2 0.2 0.4 0.4 0.6 0.3 0.7 0.5 0.5];
            o = 0;
            for i = 1:5
                o = o - ((x-aSH(i,:))*(x-aSH(i,:))' + cSH(i))^(-1);
            end
        end

        function o = F22(x)
            % F22 Shekel 7函数
            % 最优值: -10.4028 (approx)
            aSH = [4 4 4 4; 1 1 1 1; 8 8 8 8; 6 6 6 6; 3 7 3 7; ...
                   2 9 2 9; 5 5 3 3; 8 1 8 1; 6 2 6 2; 7 3.6 7 3.6];
            cSH = [0.1 0.2 0.2 0.4 0.4 0.6 0.3 0.7 0.5 0.5];
            o = 0;
            for i = 1:7
                o = o - ((x-aSH(i,:))*(x-aSH(i,:))' + cSH(i))^(-1);
            end
        end

        function o = F23(x)
            % F23 Shekel 10函数
            % 最优值: -10.5363 (approx)
            aSH = [4 4 4 4; 1 1 1 1; 8 8 8 8; 6 6 6 6; 3 7 3 7; ...
                   2 9 2 9; 5 5 3 3; 8 1 8 1; 6 2 6 2; 7 3.6 7 3.6];
            cSH = [0.1 0.2 0.2 0.4 0.4 0.6 0.3 0.7 0.5 0.5];
            o = 0;
            for i = 1:10
                o = o - ((x-aSH(i,:))*(x-aSH(i,:))' + cSH(i))^(-1);
            end
        end
    end

    methods (Static, Access = private)
        function o = Ufun(x, a, k, m)
            % Ufun 辅助惩罚函数 (用于F12和F13)
            o = k .* ((x-a).^m) .* (x>a) + k .* ((-x-a).^m) .* (x<(-a));
        end

        function type = getFunctionType(F)
            % getFunctionType 获取函数类型
            fid = str2double(F(2:end));
            if fid >= 1 && fid <= 7
                type = 'Unimodal';
            elseif fid >= 8 && fid <= 13
                type = 'Multimodal';
            else
                type = 'Fixed-dimension Multimodal';
            end
        end

        function opt = getOptimalValue(F)
            % getOptimalValue 获取理论最优值
            % 注意: 这里只给出近似值，实际值取决于维度
            switch F
                case {'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F9', 'F10', 'F11', 'F12', 'F13'}
                    opt = 0;
                case 'F8'
                    opt = -12569.5; % 对于dim=30
                case 'F14'
                    opt = 0.998;
                case 'F15'
                    opt = 0.0003075;
                case 'F16'
                    opt = -1.0316285;
                case 'F17'
                    opt = 0.397887;
                case 'F18'
                    opt = 3;
                case 'F19'
                    opt = -3.86;
                case 'F20'
                    opt = -3.32;
                case {'F21', 'F22', 'F23'}
                    opt = -10; % 近似值
                otherwise
                    opt = NaN;
            end
        end
    end
end
