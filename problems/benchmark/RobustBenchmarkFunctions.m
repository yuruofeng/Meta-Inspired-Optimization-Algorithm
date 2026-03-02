classdef RobustBenchmarkFunctions < handle
    % RobustBenchmarkFunctions 鲁棒优化基准测试函数库
    %
    % 包含8个专门设计用于测试优化算法鲁棒性的基准函数。
    % 这些函数包含各种障碍和困难，如偏置、欺骗性、多模态和平坦区域。
    %
    % 函数分类:
    %   R1-R2: 偏置函数 (Biased) - 测试算法处理搜索空间偏置的能力
    %   R3-R5: 欺骗函数 (Deceptive) - 测试算法避免被局部最优欺骗的能力
    %   R6-R7: 多模态函数 (Multimodal) - 测试算法处理多个局部最优的能力
    %   R8:    平坦函数 (Flat) - 测试算法在平坦区域的搜索能力
    %
    % 使用示例:
    %   [lb, ub, dim, fobj] = RobustBenchmarkFunctions.get('R1');
    %   x = rand(1, dim) .* (ub - lb) + lb;
    %   fitness = fobj(x);
    %
    % 参考文献:
    %   S. Mirjalili, A. Lewis, "Obstacles and difficulties for robust 
    %   benchmark problems: A novel penalty-based robust optimisation 
    %   method", Information Sciences, Vol. 328, pp. 485-509, 2016.
    %
    % 原始作者: Seyedali Mirjalili
    % 整合版本: 1.0.0
    % 日期: 2026
    % 作者: RUOFENG YU

    properties (Constant)
        FUNCTION_LIST = {'R1', 'R2', 'R3', 'R4', 'R5', 'R6', 'R7', 'R8'}
        
        FUNCTION_INFO = struct(...
            'R1', struct('name', 'TP_Biased1', 'type', 'Biased', 'description', '偏置测试问题1'), ...
            'R2', struct('name', 'TP_Biased2', 'type', 'Biased', 'description', '偏置测试问题2'), ...
            'R3', struct('name', 'TP_Deceptive1', 'type', 'Deceptive', 'description', '欺骗测试问题1'), ...
            'R4', struct('name', 'TP_Deceptive2', 'type', 'Deceptive', 'description', '欺骗测试问题2'), ...
            'R5', struct('name', 'TP_Deceptive3', 'type', 'Deceptive', 'description', '欺骗测试问题3'), ...
            'R6', struct('name', 'TP_Multimodal1', 'type', 'Multimodal', 'description', '多模态测试问题1'), ...
            'R7', struct('name', 'TP_Multimodal2', 'type', 'Multimodal', 'description', '多模态测试问题2'), ...
            'R8', struct('name', 'TP_Flat', 'type', 'Flat', 'description', '平坦区域测试问题') ...
        )
    end

    methods (Static)
        function [lb, ub, dim, fobj, delta] = get(F)
            % get 获取鲁棒基准函数配置
            %
            % 输入参数:
            %   F - 函数名称 (字符串, 'R1'-'R8')
            %
            % 输出参数:
            %   lb   - 下边界
            %   ub   - 上边界
            %   dim  - 维度 (默认2)
            %   fobj - 函数句柄
            %   delta - 容差参数 (用于鲁棒优化)

            switch F
                case 'R1'
                    fobj = @RobustBenchmarkFunctions.TP_Biased1;
                    lb = -100; ub = 100; dim = 2; delta = 1;
                    
                case 'R2'
                    fobj = @RobustBenchmarkFunctions.TP_Biased2;
                    lb = -100; ub = 100; dim = 2; delta = 1;
                    
                case 'R3'
                    fobj = @RobustBenchmarkFunctions.TP_Deceptive1;
                    lb = 0; ub = 1; dim = 2; delta = 0.01;
                    
                case 'R4'
                    fobj = @RobustBenchmarkFunctions.TP_Deceptive2;
                    lb = 0; ub = 1; dim = 2; delta = 0.01;
                    
                case 'R5'
                    fobj = @RobustBenchmarkFunctions.TP_Deceptive3;
                    lb = 0; ub = 2; dim = 2; delta = 0.01;
                    
                case 'R6'
                    fobj = @RobustBenchmarkFunctions.TP_Multimodal1;
                    lb = 0; ub = 1; dim = 2; delta = 0.01;
                    
                case 'R7'
                    fobj = @RobustBenchmarkFunctions.TP_Multimodal2;
                    lb = 0; ub = 1; dim = 2; delta = 0.01;
                    
                case 'R8'
                    fobj = @RobustBenchmarkFunctions.TP_Flat;
                    lb = 0; ub = 1; dim = 2; delta = 0.01;
                    
                otherwise
                    error('RobustBenchmarkFunctions:UnknownFunction', ...
                        'Unknown function: %s. Available: R1-R8', F);
            end
        end

        function list = list()
            % list 获取所有可用函数列表
            list = RobustBenchmarkFunctions.FUNCTION_LIST;
        end

        function info = getInfo(F)
            % getInfo 获取函数详细信息
            if isfield(RobustBenchmarkFunctions.FUNCTION_INFO, F)
                info = RobustBenchmarkFunctions.FUNCTION_INFO.(F);
            else
                error('RobustBenchmarkFunctions:UnknownFunction', ...
                    'Unknown function: %s', F);
            end
        end

        function types = getTypes()
            % getTypes 获取所有函数类型
            types = {'Biased', 'Deceptive', 'Multimodal', 'Flat'};
        end

        function funcs = getByType(typeName)
            % getByType 按类型获取函数列表
            funcs = {};
            for i = 1:length(RobustBenchmarkFunctions.FUNCTION_LIST)
                f = RobustBenchmarkFunctions.FUNCTION_LIST{i};
                if strcmp(RobustBenchmarkFunctions.FUNCTION_INFO.(f).type, typeName)
                    funcs{end+1} = f;
                end
            end
        end
    end

    methods (Static, Access = private)
        
        function o = G_penalty(x)
            % G_penalty 维度惩罚函数
            % 用于处理超过2维的决策变量
            if length(x) > 2
                o = sum(50 .* x(3:end).^2) + 1;
            else
                o = 1;
            end
        end

        function y = H_step(x)
            % H_step 阶跃函数
            if x < 0
                y = 0;
            else
                y = 1;
            end
        end

        % ==================== R1: TP_Biased1 ====================
        function o = TP_Biased1(x)
            % TP_Biased1 偏置测试问题1
            % 特点: 搜索空间存在偏置，最优解不在中心
            
            a = RobustBenchmarkFunctions.H_step(x(1)) * ...
                RobustBenchmarkFunctions.H_step(x(2));
            b = x(1)^2 + x(2)^2;
            Theta = 0.1;
            
            o = (1 - a + b / 100) * RobustBenchmarkFunctions.G_penalty(x);
            
            if (x(1)^2 + x(2)^2) > 25
                o = (sum(abs(x)).^Theta) * RobustBenchmarkFunctions.G_penalty(x);
            end
        end

        % ==================== R2: TP_Biased2 ====================
        function o = TP_Biased2(x)
            % TP_Biased2 偏置测试问题2
            % 特点: 多个偏置区域，增加搜索难度
            
            x_2 = x(1:2);
            
            c_3 = norm(x_2 + 5) / (5 * sqrt(length(x_2)));
            c_5 = norm(x_2 - 5) / (5 * sqrt(length(x_2)));
            c_4 = 5 / (5 - sqrt(5));
            
            c_1 = 625 / 624;
            c_2 = 1.5975;
            d_2 = 1.1513;
            
            f0 = 0.1 * exp(-0.5 * norm(x_2));
            f1a = c_4 * (1 - sqrt(c_3));
            f1b = c_1 * (1 - c_3^4);
            f2 = c_2 * (1 - c_5^d_2);
            
            Theta = 0.1;
            o = (c_4 - max([f0, f1a, f1b, f2])) * RobustBenchmarkFunctions.G_penalty(x);
            
            if (x(1)^2 + x(2)^2) > 0
                o = o * (sum(abs(x)).^Theta) * RobustBenchmarkFunctions.G_penalty(x);
            end
        end

        % ==================== R3: TP_Deceptive1 ====================
        function o = TP_Deceptive1(x)
            % TP_Deceptive1 欺骗测试问题1
            % 特点: 多个局部最优陷阱，容易误导算法
            
            o = (RobustBenchmarkFunctions.h_deceptive1(x(1)) + ...
                 RobustBenchmarkFunctions.h_deceptive1(x(2))) * ...
                 RobustBenchmarkFunctions.G_penalty(x) - 1;
        end

        function o = h_deceptive1(x2)
            o = 0.5 - 0.3 * exp(-((x2 - 0.2) / 0.004).^2) - ...
                       0.5 * exp(-((x2 - 0.5) / 0.05).^2) - ...
                       0.3 * exp(-((x2 - 0.8) / 0.004).^2) + sin(x2 * pi);
        end

        % ==================== R4: TP_Deceptive2 ====================
        function o = TP_Deceptive2(x)
            % TP_Deceptive2 欺骗测试问题2
            % 特点: 密集的局部最优分布
            
            o = (RobustBenchmarkFunctions.h_deceptive2(x(1)) + ...
                 RobustBenchmarkFunctions.h_deceptive2(x(2))) * ...
                 RobustBenchmarkFunctions.G_penalty(x) - 1;
        end

        function o = h_deceptive2(x2)
            l = 0.6:0.04:1;
            p = 0:0.04:0.4;
            
            o = 0.5 - 0.5 * exp(-((x2 - 0.5) / 0.05).^2) - ...
                 sum(0.3 * exp(-((x2 - l) / 0.004).^2) + ...
                     0.3 * exp(-((x2 - p) / 0.004).^2)) + sin(x2 * pi);
        end

        % ==================== R5: TP_Deceptive3 ====================
        function o = TP_Deceptive3(x)
            % TP_Deceptive3 欺骗测试问题3
            % 特点: 四个象限有不同的欺骗结构
            
            if x(1) <= 1 && x(2) <= 1
                o = RobustBenchmarkFunctions.G_penalty(x) * ...
                    (RobustBenchmarkFunctions.h_deceptive3(x(2)) + ...
                     RobustBenchmarkFunctions.h_deceptive3(x(1)));
            elseif x(1) > 1 && x(2) > 1
                o = RobustBenchmarkFunctions.G_penalty(x) * ...
                    (RobustBenchmarkFunctions.h_deceptive3(2 - x(2)) + ...
                     RobustBenchmarkFunctions.h_deceptive3(2 - x(1)));
            elseif x(1) > 1 && x(2) <= 1
                o = RobustBenchmarkFunctions.G_penalty(x) * ...
                    (RobustBenchmarkFunctions.h_deceptive3(x(2)) + ...
                     RobustBenchmarkFunctions.h_deceptive3(2 - x(1)));
            else
                o = RobustBenchmarkFunctions.G_penalty(x) * ...
                    (RobustBenchmarkFunctions.h_deceptive3(2 - x(2)) + ...
                     RobustBenchmarkFunctions.h_deceptive3(x(1)));
            end
        end

        function o = h_deceptive3(x)
            n = 4;
            beta = 1;
            o = (exp(-3 * x) .* sin((n * 2 * pi) .* x)) + (x.^beta);
        end

        % ==================== R6: TP_Multimodal1 ====================
        function o = TP_Multimodal1(x)
            % TP_Multimodal1 多模态测试问题1
            % 特点: 大量局部最优，测试全局搜索能力
            
            o = (RobustBenchmarkFunctions.h_multimodal1(x(1)) + ...
                 RobustBenchmarkFunctions.h_multimodal1(x(2))) * ...
                 RobustBenchmarkFunctions.G_penalty(x) - 1.399;
        end

        function o = h_multimodal1(x2)
            M = 0.055 / 3;
            l = 0.6:M:1;
            p = 0:M:0.4;
            
            o = 1.5 - 0.5 * exp(-((x2 - 0.5) / 0.04).^2) - ...
                 sum(0.8 * exp(-((x2 - l) / 0.004).^2) + ...
                     0.8 * exp(-((x2 - p) / 0.004).^2));
        end

        % ==================== R7: TP_Multimodal2 ====================
        function o = TP_Multimodal2(x)
            % TP_Multimodal2 多模态测试问题2
            % 特点: 对称的多模态结构
            
            o = (RobustBenchmarkFunctions.h_multimodal2(x(1)) + ...
                 RobustBenchmarkFunctions.h_multimodal2(x(2))) * ...
                 RobustBenchmarkFunctions.G_penalty(x) - 1.399;
        end

        function o = h_multimodal2(x2)
            M = 16;
            l = 0.6:((1 - 0.6) / M) + 1e-8:1;
            p = 1 - l;
            
            o = 1.5 - 0.8 * exp(-((x2 - 0.5) / 0.04).^2) - ...
                 sum(0.5 * exp(-((x2 - l) / 0.004).^2) + ...
                     0.5 * exp(-((x2 - p) / 0.004).^2));
        end

        % ==================== R8: TP_Flat ====================
        function o = TP_Flat(x)
            % TP_Flat 平坦区域测试问题
            % 特点: 大面积平坦区域，梯度信息稀少
            
            o = (RobustBenchmarkFunctions.h_flat(x(1)) + ...
                 RobustBenchmarkFunctions.h_flat(x(2))) * ...
                 RobustBenchmarkFunctions.G_penalty(x) - 2;
        end

        function o = h_flat(x2)
            n = 30;
            l = 0.95;
            p = 0.05;
            
            o = 1.2 - (0.2 * exp(-((x2 - l) / 0.03).^2) + ...
                       0.2 * exp(-((x2 - p) / 0.01).^2));
        end
    end
end
