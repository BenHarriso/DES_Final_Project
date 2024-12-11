function orderReport = orderForecast(historicalData, initialNumOfProducts, orderSize, ...
                                     minOrderSize, numOfOrders, adjustBatchSize, ...
                                     maxProductsHeld, bufferStock)
    % orderForecast: Simulates a dynamic inventory system based on historical demand data.
    %
    % Inputs:
    %   historicalData       - Array of past demand values for each order period.
    %   initialNumOfProducts - Initial stock level at the beginning.
    %   orderSize            - Size of a single order.
    %   minOrderSize         - Minimum size for placing an order.
    %   numOfOrders          - Number of order periods to simulate.
    %   adjustBatchSize      - Boolean flag: True to adjust order size dynamically, 
    %                          False to adjust order frequency while keeping size fixed.
    %   maxProductsHeld      - Maximum number of products that can be held in stock.
    %   bufferStock          - Buffer stock level to account for variability in demand.
    %
    % Outputs:
    %   orderReport          - Array of the number of products ordered in each period.
    %
    % Additional Outputs:
    %   - Generates plots for historical demand, order report, stock report, 
    %     and demand fulfillment analysis.

    %% Initialize variables
    orderReport = zeros(numOfOrders, 1) + orderSize; % Tracks the number of orders per period.
    stockReport = zeros(length(historicalData), 1); % Tracks stock levels.
    stockReport(1) = initialNumOfProducts; % Set the initial stock level.

    %% Main loop to dynamically adjust orders and maintain stock levels
    for i = 1:length(historicalData) - 1
        % Calculate the stock expected after fulfilling demand for the current period.
        expectedStock = stockReport(i) + orderReport(i) - historicalData(i);

        if adjustBatchSize
            % Adjust order size dynamically when adjustBatchSize == true.
            if expectedStock < historicalData(i + 1)
                % Case 1: Stock is insufficient to meet the next period's demand.
                shortage = (historicalData(i + 1) - stockReport(i)) + bufferStock;
                % Increase the order size to prevent shortages, constrained by max stock.
                orderReport(i) = min(orderReport(i) + shortage, maxProductsHeld);
            elseif expectedStock > historicalData(i + 1) + bufferStock
                % Case 2: Stock exceeds demand plus buffer.
                excess = expectedStock - (historicalData(i + 1) + bufferStock);
                % Reduce the order size to prevent overstocking, constrained by min order size.
                orderReport(i) = max(orderReport(i) - excess, minOrderSize);
            end
        else
            % Adjust order frequency when adjustBatchSize == false.
            while expectedStock < historicalData(i + 1)
                % Place additional orders until stock meets or exceeds demand.
                orderReport(i) = orderReport(i) + orderSize;
                expectedStock = expectedStock + orderSize;
            end

            if expectedStock > historicalData(i + 1) + bufferStock
                % Skip orders if there is excess stock.
                excessOrders = floor((expectedStock - (historicalData(i + 1) + bufferStock)) / orderSize);
                % Reduce the number of orders to prevent overstocking.
                orderReport(i) = max(orderReport(i) - excessOrders * orderSize, 0);
            end
        end

        % Update stock level for the next period.
        stockReport(i + 1) = stockReport(i) + orderReport(i) - historicalData(i);

        % Prevent negative stock levels by enforcing a minimum of zero.
        stockReport(i + 1) = max(stockReport(i + 1), 0);
    end

    %% Ensure orders remain within constraints
    % Clamp orders to the allowable range between minOrderSize and maxProductsHeld.
    for i = 1:length(orderReport)
        orderReport(i) = max(min(orderReport(i), maxProductsHeld), minOrderSize);
    end

    %% Generate plots to analyze the results
    % Plot 1: Historical demand, order report, and stock report.
    figure;
    plot(1:length(historicalData), historicalData, 'b-o', 'DisplayName', 'Historical Data'); % Historical demand.
    hold on;
    plot(1:length(orderReport), orderReport, 'r-s', 'DisplayName', 'Order Report'); % Orders placed.
    hold on;
    plot(1:length(stockReport), stockReport, 'g-^', 'DisplayName', 'Stock Report'); % Stock levels.
    legend;
    title('Historical Data, Orders, and Stock Levels');
    xlabel('Order Period');
    ylabel('Quantity of Products');
    axis([1 length(historicalData) 0 maxProductsHeld + 10]); % Adjust axis limits.
    grid on;

    % Plot 2: Demand fulfillment analysis (stock - demand difference).
    metDemand = stockReport - transpose(historicalData);
    figure;
    plot(1:length(metDemand), metDemand, 'k-*', 'DisplayName', 'Demand Fulfillment'); % Stock-demand difference.
    hold on;
    yline(0, '--r', 'DisplayName', 'Stock == Demand'); % Reference line where stock meets demand.
    legend;
    title('Met Demand Analysis');
    xlabel('Order Period');
    ylabel('Stock - Demand Difference');
    grid on;

    %% Return the order report
    % This output contains the orders placed in each period.
end
