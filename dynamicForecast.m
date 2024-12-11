function updatedOrderReport = dynamicForecast(historicalData, currentSales, ...
                                              previousOrderReport, ...
                                              currentStock, orderSize, ...
                                              minOrderSize, ...
                                              maxError, maxProductsHeld, ...
                                              adjustBatchSize, index)
    % dynamicForecast: Adjusts a single order period's forecast based on current sales
    % and the corresponding historical trend.
    %
    % Inputs:
    %   historicalData      - Array of past demand values for each order period
    %   currentSales        - The current sales data point to compare with historical data
    %   previousOrderReport - Array of the previous order report for reference
    %   currentStock        - Current stock level at the beginning of the period
    %   orderSize           - Size of a single order
    %   minOrderSize        - Minimum size for placing an order
    %   maxError            - Maximum allowable difference between historical and current sales
    %   maxProductsHeld     - Maximum number of products that can be held in stock
    %   adjustBatchSize     - Boolean to toggle between adjusting order size or frequency
    %   index               - Index indicating which historical data point is being compared
    %
    % Outputs:
    %   updatedOrderReport  - Array of adjusted orders reflecting current sales trends

    %% Initialize variables
    updatedOrderReport = previousOrderReport; % Start with the previous order report

    % Ensure the index is within bounds
    historicalIndex = index;

    % Retrieve the relevant historical data point
    historicalDemand = historicalData(historicalIndex);

    % Calculate the error between current sales and historical demand
    demandError = abs(currentSales - historicalDemand);

    %% Adjust orders if the error exceeds the threshold
    if demandError >= maxError
        if adjustBatchSize
            % Adjust orders by modifying the batch size
            if currentSales > historicalDemand
                % Case: Current sales exceed historical trend
                updatedOrderReport(index) = updatedOrderReport(index) + demandError;
            else
                % Case: Current sales are below historical trend
                updatedOrderReport(index) = updatedOrderReport(index) - demandError;
            end
        else
            % Adjust orders by modifying order frequency
            expectedStock = currentStock + updatedOrderReport(index) - currentSales;

            if currentSales > historicalDemand
                % Case: Current sales exceed historical trend
                while expectedStock < historicalDemand
                    % Place additional orders until stock meets or exceeds demand
                    updatedOrderReport(index) = updatedOrderReport(index) + orderSize;
                    expectedStock = expectedStock + orderSize;
                end
            else
                % Case: Current sales are below historical trend
                while expectedStock > historicalDemand
                    % Reduce orders until stock aligns with demand
                    updatedOrderReport(index) = updatedOrderReport(index) - orderSize;
                    expectedStock = expectedStock - orderSize;
                end
            end
        end
    end

    %% Ensure updated orders are within constraints
    if adjustBatchSize
        % Constrain batch size within min and max limits
        updatedOrderReport(index) = max(minOrderSize, min(updatedOrderReport(index), maxProductsHeld));
    else
        % Constrain orders to multiples of `orderSize`
        updatedOrderReport(index) = orderSize * round(updatedOrderReport(index) / orderSize);
    end
end
