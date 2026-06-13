classdef Phase1AlgorithmsTest < matlab.unittest.TestCase
    % Phase1AlgorithmsTest 第一阶段算法集成测试
    %
    % 测试第一阶段新增的3个优化算法:
    % - HGS (饥饿游戏搜索算法) - 单目标
    % - AO (天鹰优化器) - 单目标
    % - NSGA-III (非支配排序遗传算法III) - 多目标

    properties (Constant)
        TestConfig = struct(...
            'populationSize', 20, ...
            'maxIterations', 50, ...
            'verbose', false, ...
            'archiveMaxSize', 50 ...
        )
    end

    properties
        TestProblem
        MOProblem
    end

    methods (TestMethodSetup)
        function setupProblem(obj)
            rng(42, 'twister');
            
            obj.TestProblem = struct();
            obj.TestProblem.evaluate = @(x) sum(x.^2);
            obj.TestProblem.lb = [-5 -5 -5];
            obj.TestProblem.ub = [5 5 5];
            obj.TestProblem.dim = 3;

            obj.MOProblem = struct();
            obj.MOProblem.lb = 0;
            obj.MOProblem.ub = 1;
            obj.MOProblem.dim = 5;
            obj.MOProblem.objCount = 2;
            obj.MOProblem.evaluate = @(x) obj.zdt1(x);
        end
    end

    methods (Test)
        function testHGS(obj)
            hgs = HGS(obj.TestConfig);
            result = hgs.run(obj.TestProblem);
            
            obj.verifyTrue(isfinite(result.bestFitness), 'HGS: bestFitness should be finite');
            obj.verifyTrue(result.bestFitness >= 0, 'HGS: bestFitness should be non-negative');
            obj.verifyEqual(length(result.convergenceCurve), obj.TestConfig.maxIterations);
            obj.verifyEqual(length(result.bestSolution), obj.TestProblem.dim);
        end

        function testAO(obj)
            ao = AO(obj.TestConfig);
            result = ao.run(obj.TestProblem);
            
            obj.verifyTrue(isfinite(result.bestFitness), 'AO: bestFitness should be finite');
            obj.verifyTrue(result.bestFitness >= 0, 'AO: bestFitness should be non-negative');
            obj.verifyEqual(length(result.convergenceCurve), obj.TestConfig.maxIterations);
            obj.verifyEqual(length(result.bestSolution), obj.TestProblem.dim);
        end

        function testNSGAIII(obj)
            nsga3 = NSGAIII(obj.TestConfig);
            result = nsga3.run(obj.MOProblem);
            
            obj.verifyTrue(~isempty(result.paretoSet), 'NSGA-III: paretoSet should not be empty');
            obj.verifyTrue(~isempty(result.paretoFront), 'NSGA-III: paretoFront should not be empty');
            obj.verifyEqual(size(result.paretoFront, 2), obj.MOProblem.objCount);
            obj.verifyEqual(length(result.convergenceCurve), obj.TestConfig.maxIterations);
        end

        function testHGSInterface(obj)
            hgs = HGS(obj.TestConfig);
            
            obj.verifyTrue(isa(hgs, 'BaseAlgorithm'), 'HGS should inherit from BaseAlgorithm');
            obj.verifyTrue(ismethod(hgs, 'initialize'), 'HGS should have initialize method');
            obj.verifyTrue(ismethod(hgs, 'iterate'), 'HGS should have iterate method');
            obj.verifyTrue(ismethod(hgs, 'shouldStop'), 'HGS should have shouldStop method');
            obj.verifyTrue(ismethod(hgs, 'run'), 'HGS should have run method');
            obj.verifyTrue(ismethod(hgs, 'validateConfig'), 'HGS should have validateConfig method');
        end

        function testAOInterface(obj)
            ao = AO(obj.TestConfig);
            
            obj.verifyTrue(isa(ao, 'BaseAlgorithm'), 'AO should inherit from BaseAlgorithm');
            obj.verifyTrue(ismethod(ao, 'initialize'), 'AO should have initialize method');
            obj.verifyTrue(ismethod(ao, 'iterate'), 'AO should have iterate method');
            obj.verifyTrue(ismethod(ao, 'shouldStop'), 'AO should have shouldStop method');
            obj.verifyTrue(ismethod(ao, 'run'), 'AO should have run method');
            obj.verifyTrue(ismethod(ao, 'validateConfig'), 'AO should have validateConfig method');
        end

        function testNSGAIIIInterface(obj)
            nsga3 = NSGAIII(obj.TestConfig);
            
            obj.verifyTrue(isa(nsga3, 'MOBaseAlgorithm'), 'NSGA-III should inherit from MOBaseAlgorithm');
            obj.verifyTrue(ismethod(nsga3, 'initialize'), 'NSGA-III should have initialize method');
            obj.verifyTrue(ismethod(nsga3, 'iterate'), 'NSGA-III should have iterate method');
            obj.verifyTrue(ismethod(nsga3, 'shouldStop'), 'NSGA-III should have shouldStop method');
            obj.verifyTrue(ismethod(nsga3, 'run'), 'NSGA-III should have run method');
            obj.verifyTrue(ismethod(nsga3, 'validateConfig'), 'NSGA-III should have validateConfig method');
        end

        function testHGSSchema(obj)
            hgs = HGS();
            obj.verifyTrue(isprop(hgs, 'PARAM_SCHEMA'), 'HGS should have PARAM_SCHEMA property');
            
            schema = hgs.PARAM_SCHEMA;
            obj.verifyTrue(isfield(schema, 'populationSize'), 'HGS schema should have populationSize');
            obj.verifyTrue(isfield(schema, 'maxIterations'), 'HGS schema should have maxIterations');
            obj.verifyTrue(isfield(schema, 'hungerThreshold'), 'HGS schema should have hungerThreshold');
        end

        function testAOSchema(obj)
            ao = AO();
            obj.verifyTrue(isprop(ao, 'PARAM_SCHEMA'), 'AO should have PARAM_SCHEMA property');
            
            schema = ao.PARAM_SCHEMA;
            obj.verifyTrue(isfield(schema, 'populationSize'), 'AO schema should have populationSize');
            obj.verifyTrue(isfield(schema, 'maxIterations'), 'AO schema should have maxIterations');
        end

        function testNSGAIIISchema(obj)
            nsga3 = NSGAIII();
            obj.verifyTrue(isprop(nsga3, 'PARAM_SCHEMA'), 'NSGA-III should have PARAM_SCHEMA property');
            
            schema = nsga3.PARAM_SCHEMA;
            obj.verifyTrue(isfield(schema, 'populationSize'), 'NSGA-III schema should have populationSize');
            obj.verifyTrue(isfield(schema, 'maxIterations'), 'NSGA-III schema should have maxIterations');
            obj.verifyTrue(isfield(schema, 'crossoverProb'), 'NSGA-III schema should have crossoverProb');
            obj.verifyTrue(isfield(schema, 'mutationProb'), 'NSGA-III schema should have mutationProb');
            obj.verifyTrue(isfield(schema, 'divisions'), 'NSGA-III schema should have divisions');
        end

        function testHGSCustomParams(obj)
            customConfig = struct(...
                'populationSize', 15, ...
                'maxIterations', 25, ...
                'hungerThreshold', 0.5, ...
                'verbose', false ...
            );
            
            hgs = HGS(customConfig);
            result = hgs.run(obj.TestProblem);
            
            obj.verifyEqual(length(result.convergenceCurve), 25, ...
                'HGS custom maxIterations should be respected');
        end

        function testAOCustomParams(obj)
            customConfig = struct(...
                'populationSize', 25, ...
                'maxIterations', 30, ...
                'verbose', false ...
            );
            
            ao = AO(customConfig);
            result = ao.run(obj.TestProblem);
            
            obj.verifyEqual(length(result.convergenceCurve), 30, ...
                'AO custom maxIterations should be respected');
        end

        function testNSGAIIICustomParams(obj)
            customConfig = struct(...
                'populationSize', 30, ...
                'maxIterations', 40, ...
                'archiveMaxSize', 30, ...
                'crossoverProb', 0.8, ...
                'mutationProb', 0.15, ...
                'verbose', false ...
            );
            
            nsga3 = NSGAIII(customConfig);
            result = nsga3.run(obj.MOProblem);
            
            obj.verifyEqual(length(result.convergenceCurve), 40, ...
                'NSGA-III custom maxIterations should be respected');
        end

        function testHGSBoundaryConstraints(obj)
            hgs = HGS(obj.TestConfig);
            result = hgs.run(obj.TestProblem);
            
            for i = 1:length(result.bestSolution)
                obj.verifyTrue(result.bestSolution(i) >= obj.TestProblem.lb(i), ...
                    'HGS solution should respect lower bounds');
                obj.verifyTrue(result.bestSolution(i) <= obj.TestProblem.ub(i), ...
                    'HGS solution should respect upper bounds');
            end
        end

        function testAOBoundaryConstraints(obj)
            ao = AO(obj.TestConfig);
            result = ao.run(obj.TestProblem);
            
            for i = 1:length(result.bestSolution)
                obj.verifyTrue(result.bestSolution(i) >= obj.TestProblem.lb(i), ...
                    'AO solution should respect lower bounds');
                obj.verifyTrue(result.bestSolution(i) <= obj.TestProblem.ub(i), ...
                    'AO solution should respect upper bounds');
            end
        end

        function testNSGAIIIBoundaryConstraints(obj)
            nsga3 = NSGAIII(obj.TestConfig);
            result = nsga3.run(obj.MOProblem);
            
            for i = 1:size(result.paretoSet, 1)
                for j = 1:size(result.paretoSet, 2)
                    obj.verifyTrue(result.paretoSet(i, j) >= obj.MOProblem.lb, ...
                        'NSGA-III paretoSet should respect lower bounds');
                    obj.verifyTrue(result.paretoSet(i, j) <= obj.MOProblem.ub, ...
                        'NSGA-III paretoSet should respect upper bounds');
                end
            end
        end

        function testHGSConvergence(obj)
            hgs = HGS(obj.TestConfig);
            result = hgs.run(obj.TestProblem);
            
            obj.verifyTrue(result.convergenceCurve(1) >= result.bestFitness, ...
                'HGS should converge (initial >= final)');
        end

        function testAOConvergence(obj)
            ao = AO(obj.TestConfig);
            result = ao.run(obj.TestProblem);
            
            obj.verifyTrue(result.convergenceCurve(1) >= result.bestFitness, ...
                'AO should converge (initial >= final)');
        end

        function testAlgorithmRegistration(obj)
            obj.verifyTrue(ismethod(HGS, 'register'), 'HGS should have register method');
            obj.verifyTrue(ismethod(AO, 'register'), 'AO should have register method');
            obj.verifyTrue(ismethod(NSGAIII, 'register'), 'NSGA-III should have register method');
        end
    end

    methods (Access = private)
        function f = zdt1(~, x)
            % zdt1 ZDT1多目标测试函数
            %
            % 输入参数:
            %   x - 决策变量向量
            %
            % 输出参数:
            %   f - 目标函数值 [f1, f2]

            n = length(x);
            f1 = x(1);
            g = 1 + 9 * sum(x(2:end)) / (n - 1);
            h = 1 - sqrt(f1 / g);
            f2 = g * h;
            f = [f1, f2];
        end
    end
end
