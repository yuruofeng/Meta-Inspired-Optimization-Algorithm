classdef AlgorithmRegistryMetadataTest < matlab.unittest.TestCase
    % AlgorithmRegistryMetadataTest 验证注册表兼容调用和元数据输出

    methods (TestMethodSetup)
        function clearRegistry(~)
            AlgorithmRegistry.clear();
        end
    end

    methods (Test)
        function testRegisterAcceptsFunctionHandleWithoutVersion(testCase)
            AlgorithmRegistry.register('PSO_TEST', @PSO);

            testCase.verifyTrue(AlgorithmRegistry.isRegistered('PSO_TEST'));
            constructor = AlgorithmRegistry.getAlgorithm('PSO_TEST');
            testCase.verifyEqual(func2str(constructor), 'PSO');
        end

        function testRegisterAcceptsStringClassWithVersion(testCase)
            AlgorithmRegistry.register('AO_TEST', '1.0.0', 'AO');

            testCase.verifyTrue(AlgorithmRegistry.isRegistered('AO_TEST', '1.0.0'));
            constructor = AlgorithmRegistry.getAlgorithm('AO_TEST', '1.0.0');
            testCase.verifyEqual(func2str(constructor), 'AO');
        end

        function testMetadataComesFromRegisteredClassSchema(testCase)
            AlgorithmRegistry.register('GWO_TEST', '2.0.0', @GWO);

            metadata = AlgorithmRegistry.listMetadata();
            testCase.verifyEqual(metadata.id, 'GWO_TEST');
            testCase.verifyEqual(metadata.version, '2.0.0');
            testCase.verifyTrue(isfield(metadata.paramSchema, 'populationSize'));
            testCase.verifyTrue(isfield(metadata.paramSchema, 'maxIterations'));
        end

        function testApiGetMetadataUsesRegistry(testCase)
            AlgorithmRegistry.register('WOA_TEST', '2.0.0', @WOA);

            payload = jsondecode(apiGetMetadata('algorithms'));
            testCase.verifyEqual(payload.id, 'WOA_TEST');
            testCase.verifyEqual(payload.version, '2.0.0');
            testCase.verifyTrue(isfield(payload.paramSchema, 'populationSize'));
        end

        function testRegisterAllAlgorithmsLoadsDeclaredCatalog(testCase)
            expectedIds = { ...
                'GWO', 'ALO', 'WOA', 'DA', 'MFO', 'MVO', 'SCA', 'SSA', ...
                'IGWO', 'EWOA', 'BDA', 'BBA', 'GA', 'SA', 'VPSO', 'VPPSO', ...
                'WOASA', 'PSOGSA', 'GOA', 'HLBDA', 'HGS', 'AO', 'MPA', ...
                'GTO', 'MOEAD', 'AVOA', 'KOA', 'RIME', 'MOALO', 'MODA', ...
                'MOGOA', 'MOGWO', 'MSSA', 'NSGAIII' ...
            };

            registerAllAlgorithms();
            metadata = AlgorithmRegistry.listMetadata();
            actualIds = {metadata.id};

            testCase.verifyEqual(numel(actualIds), numel(expectedIds));
            for i = 1:numel(expectedIds)
                testCase.verifyTrue(any(strcmp(actualIds, expectedIds{i})), ...
                    sprintf('Expected algorithm %s to be registered', expectedIds{i}));
            end
        end
    end
end
