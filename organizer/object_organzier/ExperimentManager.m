classdef ExperimentManager
    properties
        Animals
    end

    methods
        function obj = ExperimentManager(animalList)
            obj.Animals = animalList;
        end

        function results = runMethod(obj, methodName, varargin)
            results = cell(1, numel(obj.Animals));
            for i = 1:numel(obj.Animals)
                a = obj.Animals(i);
                if ismethod(a, methodName)
                    results{i} = a.(methodName)(varargin{:});
                else
                    warning('Method %s not found in Animal.', methodName);
                end
            end
        end

        function selected = selectByArea(obj, area)
            selected = obj.Animals(arrayfun(@(a) any(strcmp(a.Areas, area)), obj.Animals));
        end
    end
end
