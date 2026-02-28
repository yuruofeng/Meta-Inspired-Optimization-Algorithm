classdef MOAlgorithmTest < matlab.unittest.TestCase
    % MOAlgorithmTest 多目标算法综合单元测试
    %
    % 测试所有多目标优化算法的基本功能、收敛性和Pareto前沿质量
    %
    % 作者：RUOFENG YU
    % 版本: 1.0.0
    % 日期: 2025

    properties
        ZDT1Problem        % ZDT1测试问题
        smallConfig        % 小规模配置（快速测试）
    end

    methods (TestMethodSetup)
        function setupProblem(testCase)
            testCase.ZDT1Problem = struct();
            testCase.ZDT1Problem.lb = 0;
            testCase.ZDT1Problem.ub = 1;
            testCase.ZDT1Problem.dim = 5;
            testCase.ZDT1Problem.objCount = 2;
            testCase.ZDT1Problem.evaluate = @(x) testCase.zdt1Evaluate(x);

            testCase.smallConfig = struct();
            testCase.smallConfig.populationSize = 20;
            testCase.smallConfig.maxIterations = 20;
            testCase.smallConfig.archiveMaxSize = 30;
            testCase.smallConfig.verbose = false;
        end
    end

    methods (Test)
        function testMOALOBasic(testCase)
            testCase.testMOAlgorithmBasic('MOALO', @MOALO);
        end

        function testMODABasic(testCase)
            testCase.testMOAlgorithmBasic('MODA', @MODA);
        end

        function testMOGOABasic(testCase)
            testCase.testMOAlgorithmBasic('MOGOA', @MOGOA);
        end

        function testMOGWOBasic(testCase)
            testCase.testMOAlgorithmBasic('MOGWO', @MOGWO);
        end

        function testMSSABasic(testCase)
            testCase.testMOAlgorithmBasic('MSSA', @MSSA);
        end

        function testMOALOConvergence(testCase)
            testCase.testMOAlgorithmConvergence('MOALO', @MOALO);
        end

        function testMODAConvergence(testCase)
            testCase.testMOAlgorithmConvergence('MODA', @MODA);
        end

        function testMOGOAConvergence(testCase)
            testCase.testMOAlgorithmConvergence('MOGOA', @MOGOA);
        end

        function testMOGWOConvergence(testCase)
            testCase.testMOAlgorithmConvergence('MOGWO', @MOGWO);
        end

        function testMSSAConvergence(testCase)
            testCase.testMOAlgorithmConvergence('MSSA', @MSSA);
        end

        function testMOALODefaultConfig(testCase)
            moalo = MOALO();
            testCase.assertEqual(moalo.config.populationSize, 100);
            testCase.assertEqual(moalo.config.maxIterations, 100);
            testCase.assertEqual(moalo.config.archiveMaxSize, 100);
            testCase.assertEqual(moalo.config.verbose, true);
        end

        function testMODADefaultConfig(testCase)
            moda = MODA();
            testCase.assertEqual(moda.config.populationSize, 100);
            testCase.assertEqual(moda.config.maxIterations, 100);
            testCase.assertEqual(moda.config.archiveMaxSize, 100);
        end

        function testMOGOADefaultConfig(testCase)
            mogoa = MOGOA();
            testCase.assertEqual(mogoa.config.populationSize, 200);
            testCase.assertEqual(mogoa.config.maxIterations, 100);
            testCase.assertEqual(mogoa.config.archiveMaxSize, 100);
            testCase.assertEqual(mogoa.config.cMax, 1);
            testCase.assertEqual(mogoa.config.cMin, 0.00004);
        end

        function testMOGWODefaultConfig(testCase)
            mogwo = MOGWO();
            testCase.assertEqual(mogwo.config.populationSize, 100);
            testCase.assertEqual(mogwo.config.maxIterations, 100);
            testCase.assertEqual(mogwo.config.archiveMaxSize, 100);
            testCase.assertEqual(mogwo.config.nGrid, 10);
        end

        function testMSSADefaultConfig(testCase)
            mssa = MSSA();
            testCase.assertEqual(mssa.config.populationSize, 200);
            testCase.assertEqual(mssa.config.maxIterations, 100);
            testCase.assertEqual(mssa.config.archiveMaxSize, 100);
        end

        function testMOALOCustomConfig(testCase)
            config = struct();
            config.populationSize = 50;
            config.maxIterations = 50;
            config.archiveMaxSize = 50;
            config.verbose = false;

            moalo = MOALO(config);
            testCase.assertEqual(moalo.config.populationSize, 50);
            testCase.assertEqual(moalo.config.maxIterations, 50);
            testCase.assertEqual(moalo.config.archiveMaxSize, 50);
        end

        function testMOGWOParameters(testCase)
            config = struct();
            config.nGrid = 20;
            config.alpha = 0.2;
            config.beta = 5;
            config.gamma = 3;
            config.verbose = false;

            mogwo = MOGWO(config);
            testCase.assertEqual(mogwo.config.nGrid, 20);
            testCase.assertEqual(mogwo.config.alpha, 0.2);
            testCase.assertEqual(mogwo.config.beta, 5);
            testCase.assertEqual(mogwo.config.gamma, 3);
        end

        function testParetoFrontQuality(testCase)
            rng(42, 'twister');

            moalo = MOALO(testCase.smallConfig);
            result = moalo.run(testCase.ZDT1Problem);

            testCase.assertTrue(result.archiveSize > 0);
            testCase.assertTrue(size(result.paretoFront, 1) > 0);

            pf = result.paretoFront;
            testCase.assertTrue(all(pf(:, 1) >= 0));
            testCase.assertTrue(all(pf(:, 1) <= 1));
            testCase.assertTrue(all(pf(:, 2) >= 0));
        end

        function testDominanceOperator(testCase)
            domOp = algorithms.mo.operators.DominanceOperator();

            x = [1, 2];
            y = [2, 3];
            testCase.assertTrue(domOp.dominates(x, y));
            testCase.assertFalse(domOp.dominates(y, x));

            z = [1, 3];
            testCase.assertFalse(domOp.dominates(x, z));
            testCase.assertFalse(domOp.dominates(z, x));
        end

        function testArchiveManager(testCase)
            archive = algorithms.mo.operators.ArchiveManager(10, 5, 2);

            newSolutions = rand(5, 5);
            newFitness = rand(5, 2);

            archive.update(newSolutions, newFitness);

            testCase.assertTrue(archive.getSize() > 0);
            testCase.assertTrue(archive.getSize() <= 10);
        end

        function testMOOptimizationResult(testCase)
            pf = rand(10, 2);
            ps = rand(10, 5);

            result = MOOptimizationResult(...
                'paretoSet', ps, ...
                'paretoFront', pf, ...
                'objCount', 2, ...
                'elapsedTime', 1.5);

            testCase.assertEqual(size(result.paretoFront, 1), 10);
            testCase.assertEqual(size(result.paretoSet, 2), 5);
            testCase.assertEqual(result.elapsedTime, 1.5);
        end

        function testBoundaryHandling(testCase)
            rng(42, 'twister');

            config = testCase.smallConfig;

            moalo = MOALO(config);
            result = moalo.run(testCase.ZDT1Problem);

            ps = result.paretoSet;
            testCase.assertTrue(all(ps(:) >= 0));
            testCase.assertTrue(all(ps(:) <= 1));
        end

        function testMultiObjectiveEvaluation(testCase)
            rng(42, 'twister');

            moalo = MOALO(testCase.smallConfig);
            result = moalo.run(testCase.ZDT1Problem);

            testCase.assertEqual(result.objCount, 2);
            testCase.assertEqual(size(result.paretoFront, 2), 2);
        end
    end

    methods
        function testMOAlgorithmBasic(testCase, name, constructor)
            rng(42, 'twister');

            algo = constructor(testCase.smallConfig);
            result = algo.run(testCase.ZDT1Problem);

            testCase.assertEqual(class(result), 'MOOptimizationResult');
            testCase.assertTrue(isfield(result, 'paretoFront'));
            testCase.assertTrue(isfield(result, 'paretoSet'));
            testCase.assertTrue(result.archiveSize > 0);
            testCase.assertEqual(size(result.paretoFront, 2), 2);
        end

        function testMOAlgorithmConvergence(testCase, name, constructor)
            rng(42, 'twister');

            algo = constructor(testCase.smallConfig);
            result = algo.run(testCase.ZDT1Problem);

            testCase.assertTrue(result.totalEvaluations > 0);
            testCase.assertTrue(result.elapsedTime > 0);
            testCase.assertEqual(length(result.convergenceCurve), testCase.smallConfig.maxIterations);
        end

        function fitness = zdt1Evaluate(testCase, x)
            n = length(x);
            f1 = x(1);
            g = 1 + 9 * sum(x(2:n)) / (n - 1);
            h = 1 - sqrt(f1 / g);
            f2 = g * h;
            fitness = [f1, f2];
        end
    end
end
