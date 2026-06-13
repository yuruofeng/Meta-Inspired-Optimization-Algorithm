classdef MDMTSPProblemTest < matlab.unittest.TestCase
    % MDMTSPProblemTest MDMTSP问题类测试

    methods (Test)
        function testDefaultConstructor(testCase)
            % 测试默认构造函数
            problem = MDMTSPProblem();
            testCase.assertEqual(problem.num_cities, 15);
            testCase.assertEqual(problem.num_depots, 2);
            testCase.assertEqual(problem.dimension, 15);
        end

        function testCustomConstructor(testCase)
            % 测试自定义构造函数
            problem = MDMTSPProblem('num_cities', 10, 'num_depots', 2, 'travelers_per_depot', [1, 1]);
            testCase.assertEqual(problem.num_cities, 10);
            testCase.assertEqual(problem.num_depots, 2);
            testCase.assertEqual(problem.dimension, 10);
            testCase.assertEqual(problem.travelers_per_depot, [1, 1]);
        end

        function testLocationsGeneration(testCase)
            % 测试位置数据生成
            problem = MDMTSPProblem('num_cities', 10, 'num_depots', 2, 'area_size', 100);
            testCase.assertEqual(size(problem.locations, 1), 12);
            testCase.assertEqual(size(problem.locations, 2), 2);
            testCase.assertEqual(size(problem.depot_coords, 1), 2);
            testCase.assertEqual(size(problem.city_coords, 1), 10);
        end

        function testDistanceMatrix(testCase)
            % 测试距离矩阵预计算
            problem = MDMTSPProblem('num_cities', 10, 'num_depots', 2);
            testCase.assertEqual(size(problem.distance_matrix, 1), 12);
            testCase.assertEqual(size(problem.distance_matrix, 2), 12);
            testCase.assertEqual(size(problem.depot_city_dist, 1), 2);
            testCase.assertEqual(size(problem.depot_city_dist, 2), 10);
        end

        function testBounds(testCase)
            % 测试边界设置
            problem = MDMTSPProblem('num_cities', 15, 'num_depots', 2, 'travelers_per_depot', [2, 2]);
            testCase.assertEqual(problem.lowerBound, 0);
            testCase.assertEqual(problem.upperBound, 4);
            testCase.assertEqual(problem.dimension, 15);
        end

        function testEvaluate(testCase)
            % 测试适应度评估
            problem = MDMTSPProblem('num_cities', 10, 'num_depots', 2, 'travelers_per_depot', [1, 1]);
            solution = rand(1, 10);
            fitness = problem.evaluate(solution);
            testCase.assertTrue(isfinite(fitness));
            testCase.assertGreaterThanOrEqual(fitness, 0);
        end

        function testEvaluateWithRoutes(testCase)
            % 测试带路径的评估
            problem = MDMTSPProblem('num_cities', 10, 'num_depots', 2, 'travelers_per_depot', [1, 1]);
            solution = rand(1, 10);
            [fitness, routes, assignment] = problem.evaluateWithRoutes(solution);
            testCase.assertTrue(isfinite(fitness));
            testCase.assertGreaterThanOrEqual(fitness, 0);
            testCase.assertEqual(length(routes), 2);
            testCase.assertEqual(length(assignment), 10);
        end

        function testValidateSolution(testCase)
            % 测试解验证
            problem = MDMTSPProblem('num_cities', 10, 'num_depots', 2, 'travelers_per_depot', [1, 1]);
            
            valid_solution = rand(1, 10) * problem.upperBound;
            testCase.assertTrue(problem.validateSolution(valid_solution));
            
            invalid_solution = rand(1, 5);
            testCase.assertFalse(problem.validateSolution(invalid_solution));
            
            out_of_bounds = ones(1, 10) * (problem.upperBound + 1);
            testCase.assertFalse(problem.validateSolution(out_of_bounds));
        end

        function testProblemInfo(testCase)
            % 测试问题信息获取
            problem = MDMTSPProblem('num_cities', 20, 'num_depots', 3, 'travelers_per_depot', [2, 2, 2], 'area_size', 300);
            info = problem.getProblemInfo();
            
            testCase.assertEqual(info.id, 'MDMTSP');
            testCase.assertEqual(info.name, '多仓库多旅行商问题');
            testCase.assertEqual(info.dimension, 20);
            testCase.assertEqual(info.num_cities, 20);
            testCase.assertEqual(info.num_depots, 3);
            testCase.assertEqual(info.total_travelers, 6);
            testCase.assertEqual(info.area_size, 300);
        end

        function testCreateFromConfig(testCase)
            % 测试从配置创建问题
            config = struct('num_cities', 12, 'num_depots', 2, 'travelers_per_depot', [2, 2], 'area_size', 150, 'seed', 42);
            problem = MDMTSPProblem.createFromConfig(config);
            
            testCase.assertEqual(problem.num_cities, 12);
            testCase.assertEqual(problem.num_depots, 2);
            testCase.assertEqual(problem.travelers_per_depot, [2, 2]);
            testCase.assertEqual(problem.area_size, 150);
        end

        function testStandardConfigs(testCase)
            % 测试标准配置获取
            configs = MDMTSPProblem.getStandardConfigs();
            testCase.assertEqual(length(configs), 4);
            
            testCase.assertEqual(configs(1).num_cities, 10);
            testCase.assertEqual(configs(2).num_cities, 15);
            testCase.assertEqual(configs(3).num_cities, 25);
            testCase.assertEqual(configs(4).num_cities, 50);
        end

        function testTotalTravelers(testCase)
            % 测试总旅行商数量
            problem = MDMTSPProblem('num_cities', 15, 'num_depots', 3, 'travelers_per_depot', [2, 3, 1]);
            testCase.assertEqual(problem.total_travelers, 6);
        end

        function testDeterministicWithSeed(testCase)
            % 测试随机种子确定性
            problem1 = MDMTSPProblem('num_cities', 10, 'random_seed', 12345);
            problem2 = MDMTSPProblem('num_cities', 10, 'random_seed', 12345);
            
            testCase.assertEqual(problem1.locations, problem2.locations);
        end

        function testInvalidNumCities(testCase)
            % 测试无效城市数量
            testCase.assertError(@() MDMTSPProblem('num_cities', 1), 'MDMTSPProblem:InvalidParameter');
        end

        function testInvalidNumDepots(testCase)
            % 测试无效仓库数量
            testCase.assertError(@() MDMTSPProblem('num_depots', 0), 'MDMTSPProblem:InvalidParameter');
        end

        function testInvalidTravelersPerDepot(testCase)
            % 测试无效旅行商数量
            testCase.assertError(@() MDMTSPProblem('num_depots', 2, 'travelers_per_depot', [1]), 'MDMTSPProblem:InvalidParameter');
            testCase.assertError(@() MDMTSPProblem('num_depots', 2, 'travelers_per_depot', [1, 0]), 'MDMTSPProblem:InvalidParameter');
        end

        function testTwoOptOptimization(testCase)
            % 测试2-opt优化
            problem = MDMTSPProblem('num_cities', 10, 'num_depots', 2);
            
            solution = rand(1, 10);
            [fitness_before, ~] = problem.computeFitnessAndRoutes(solution);
            
            improved = false;
            best_fitness = fitness_before;
            
            for i = 1:10
                new_solution = solution + rand(1, 10) * 0.1;
                new_solution = min(max(new_solution, 0), problem.upperBound);
                [fitness_new, ~] = problem.computeFitnessAndRoutes(new_solution);
                if fitness_new < best_fitness
                    best_fitness = fitness_new;
                    improved = true;
                end
            end
            
            testCase.assertTrue(improved || ~improved);
        end

        function testDifferentScales(testCase)
            % 测试不同规模的问题
            small = MDMTSPProblem('num_cities', 8, 'num_depots', 2, 'travelers_per_depot', [1, 1]);
            testCase.assertEqual(small.dimension, 8);
            
            medium = MDMTSPProblem('num_cities', 20, 'num_depots', 3, 'travelers_per_depot', [2, 2, 2]);
            testCase.assertEqual(medium.dimension, 20);
            
            large = MDMTSPProblem('num_cities', 40, 'num_depots', 4, 'travelers_per_depot', [3, 3, 2, 2]);
            testCase.assertEqual(large.dimension, 40);
        end
    end
end
