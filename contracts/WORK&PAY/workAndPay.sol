// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title WorkAndPayCarSystem
 * @dev A smart contract for managing 'Work and Pay' car agreements.
 * Owners can list cars, assign them to drivers, and drivers make installment payments.
 * The contract tracks payments and allows owners to reclaim defaulting cars.
 */
contract WorkAndPayCarSystem {

    // Struct to represent a car under a 'Work and Pay' agreement
    struct Car {
        uint256 id;                   // Unique ID for the car
        string make;                  // Car manufacturer
        string model;                 // Car model
        uint256 year;                 // Manufacturing year
        address payable owner;        // Original owner of the car (who initiated the W&P agreement)

        bool isAvailableForAssignment; // True if the car is listed but not yet assigned to a driver
        bool isUnderWorkAndPay;       // True if the car is currently assigned to a driver under W&P
        address currentDriver;        // Address of the driver currently in the W&P agreement (address(0) if not assigned)

        uint256 totalSalesPrice;      // Total amount driver needs to pay to 'buy' the car in Wei
        uint256 installmentAmount;    // Amount due per payment interval in Wei
        uint256 paymentFrequencyDays; // How often payments are due, in days (e.g., 7 for weekly, 30 for monthly)
        uint256 lastPaymentTime;      // Timestamp of the last successful installment payment for the current driver
        uint256 amountPaidByDriver;   // Total amount paid by the current driver for THIS agreement in Wei
        bool isPaidOff;               // True if the total sales price has been paid by the current driver
    }

    // Mapping to store cars by their unique ID
    mapping(uint256 => Car) public cars;
    // Counter for generating unique car IDs
    uint256 public carCount;

    // Events to log important actions and state changes
    event WorkAndPayCarAdded(
        uint256 indexed carId,
        address indexed owner,
        string make,
        string model,
        uint256 totalSalesPrice,
        uint256 installmentAmount,
        uint256 paymentFrequencyDays
    );
    event CarAssigned(
        uint256 indexed carId,
        address indexed owner,
        address indexed driver,
        uint256 assignmentTime
    );
    event InstallmentPaid(
        uint256 indexed carId,
        address indexed driver,
        uint256 amountPaidThisInstallment,
        uint256 totalAmountPaid
    );
    event CarReclaimed(
        uint256 indexed carId,
        address indexed owner,
        address indexed previousDriver,
        uint256 reclaimTime
    );
    event CarPaidOff(
        uint256 indexed carId,
        address indexed driver,
        address indexed originalOwner,
        uint256 finalPaymentTime
    );

    /**
     * @dev Modifier to restrict access to the car's original owner.
     */
    modifier onlyOwner(uint256 _carId) {
        require(msg.sender == cars[_carId].owner, "Only the car owner can call this function.");
        _;
    }

    /**
     * @dev Modifier to ensure the car is currently available for assignment.
     */
    modifier onlyAvailableForAssignment(uint256 _carId) {
        require(cars[_carId].isAvailableForAssignment, "Car is not available for assignment.");
        _;
    }

    /**
     * @dev Modifier to ensure the car is currently under a Work and Pay agreement.
     */
    modifier onlyIfUnderWorkAndPay(uint256 _carId) {
        require(cars[_carId].isUnderWorkAndPay, "Car is not currently under a Work and Pay agreement.");
        _;
    }

    /**
     * @dev Modifier to ensure the caller is the current assigned driver of the car.
     */
    modifier onlyAssignedDriver(uint256 _carId) {
        require(msg.sender == cars[_carId].currentDriver, "Only the assigned driver can call this function.");
        _;
    }

    constructor() {
        carCount = 0; // Initialize car count
    }

    /**
     * @dev Adds a new car to be available for a 'Work and Pay' agreement.
     * @param _make The make of the car.
     * @param _model The model of the car.
     * @param _year The manufacturing year of the car.
     * @param _totalSalesPrice The total amount the driver needs to pay to acquire the car (in Wei).
     * @param _installmentAmount The amount required for each installment payment (in Wei).
     * @param _paymentFrequencyDays The interval between payments, in days (e.g., 7 for weekly).
     */
    function addWorkAndPayCar(
        string calldata _make,
        string calldata _model,
        uint256 _year,
        uint256 _totalSalesPrice,
        uint256 _installmentAmount,
        uint256 _paymentFrequencyDays
    ) public {
        require(_totalSalesPrice > 0, "Total sales price must be greater than zero.");
        require(_installmentAmount > 0, "Installment amount must be greater than zero.");
        require(_paymentFrequencyDays > 0, "Payment frequency must be greater than zero days.");
        require(_installmentAmount <= _totalSalesPrice, "Installment amount cannot exceed total sales price.");

        carCount++; // Increment car count for new ID
        cars[carCount] = Car(
            carCount,
            _make,
            _model,
            _year,
            payable(msg.sender),        // The sender is the original owner
            true,                        // Initially available for assignment
            false,                       // Not yet under W&P agreement
            address(0),                  // No driver initially
            _totalSalesPrice,
            _installmentAmount,
            _paymentFrequencyDays,
            0,                           // No last payment time initially
            0,                           // No amount paid initially
            false                        // Not paid off initially
        );
        emit WorkAndPayCarAdded(carCount, msg.sender, _make, _model, _totalSalesPrice, _installmentAmount, _paymentFrequencyDays);
    }

    /**
     * @dev Assigns an available 'Work and Pay' car to a driver.
     * Only the car owner can assign it.
     * @param _carId The ID of the car to assign.
     * @param _driverAddress The address of the driver to assign the car to.
     */
    function assignCarToDriver(uint256 _carId, address _driverAddress)
        public
        onlyOwner(_carId)
        onlyAvailableForAssignment(_carId)
    {
        require(_carId > 0 && _carId <= carCount, "Invalid car ID.");
        require(_driverAddress != address(0), "Driver address cannot be zero.");

        Car storage car = cars[_carId];
        car.isAvailableForAssignment = false;
        car.isUnderWorkAndPay = true;
        car.currentDriver = _driverAddress;
        car.lastPaymentTime = block.timestamp; // First payment period starts now
        car.amountPaidByDriver = 0; // Reset for this new agreement
        car.isPaidOff = false; // Reset for this new agreement

        emit CarAssigned(_carId, msg.sender, _driverAddress, block.timestamp);
    }

    /**
     * @dev Allows the assigned driver to make an installment payment.
     * The payment amount must be at least the required installment.
     * @param _carId The ID of the car for which to make a payment.
     */
    function makeInstallmentPayment(uint256 _carId)
        public
        payable
        onlyAssignedDriver(_carId)
        onlyIfUnderWorkAndPay(_carId)
    {
        require(_carId > 0 && _carId <= carCount, "Invalid car ID.");
        Car storage car = cars[_carId];

        // Ensure at least the installment amount is sent
        require(msg.value >= car.installmentAmount, "Insufficient payment: must send at least the installment amount.");

        // Check if payment is overdue (optional grace period can be added here)
        uint256 nextPaymentDueTime = car.lastPaymentTime + (car.paymentFrequencyDays * 1 days);
        require(block.timestamp >= nextPaymentDueTime || car.amountPaidByDriver == 0, "Payment not due yet or car not assigned.");

        // Transfer payment to the owner
        (bool success, ) = car.owner.call{value: msg.value}("");
        require(success, "Failed to transfer funds to owner.");

        car.amountPaidByDriver += msg.value;
        car.lastPaymentTime = block.timestamp;

        // Check if the car is fully paid off
        if (car.amountPaidByDriver >= car.totalSalesPrice) {
            car.isPaidOff = true;
            car.isUnderWorkAndPay = false; // Agreement concluded
            car.isAvailableForAssignment = false; // No longer available for new W&P as it's paid off
            car.currentDriver = address(0); // Clear driver as agreement is over

            // Refund any overpayment
            uint256 overpayment = car.amountPaidByDriver - car.totalSalesPrice;
            if (overpayment > 0) {
                payable(msg.sender).transfer(overpayment);
            }

            emit CarPaidOff(_carId, msg.sender, car.owner, block.timestamp);
        }

        emit InstallmentPaid(_carId, msg.sender, msg.value, car.amountPaidByDriver);
    }

    /**
     * @dev Allows the original owner to reclaim a car if the driver has defaulted on payments.
     * A car is considered defaulted if the current time is beyond the next due payment time
     * and the total amount paid is less than the total sales price.
     * @param _carId The ID of the car to reclaim.
     */
    function reclaimCar(uint256 _carId)
        public
        onlyOwner(_carId)
        onlyIfUnderWorkAndPay(_carId)
    {
        require(_carId > 0 && _carId <= carCount, "Invalid car ID.");
        Car storage car = cars[_carId];

        require(!car.isPaidOff, "Car is already paid off.");

        // Calculate the next expected payment due time
        uint256 nextPaymentDueTime = car.lastPaymentTime + (car.paymentFrequencyDays * 1 days);

        // Check if the payment is overdue
        require(block.timestamp > nextPaymentDueTime, "Payment is not yet overdue.");

        // Store previous driver for event logging
        address previousDriver = car.currentDriver;

        // Reset car status to be available for assignment again
        car.isAvailableForAssignment = true;
        car.isUnderWorkAndPay = false;
        car.currentDriver = address(0);
        car.lastPaymentTime = 0; // Reset payment tracking
        car.amountPaidByDriver = 0; // Reset paid amount for new agreement

        emit CarReclaimed(_carId, msg.sender, previousDriver, block.timestamp);
    }

    /**
     * @dev Retrieves details of a specific 'Work and Pay' car.
     * @param _carId The ID of the car.
     * @return All relevant details of the car for Work and Pay.
     */
    function getCarDetails(uint256 _carId)
        public
        view
        returns (
            uint256 id,
            string memory make,
            string memory model,
            uint256 year,
            address owner,
            bool isAvailableForAssignment,
            bool isUnderWorkAndPay,
            address currentDriver,
            uint256 totalSalesPrice,
            uint256 installmentAmount,
            uint256 paymentFrequencyDays,
            uint256 lastPaymentTime,
            uint256 amountPaidByDriver,
            bool isPaidOff
        )
    {
        require(_carId > 0 && _carId <= carCount, "Invalid car ID.");
        Car storage car = cars[_carId];
        return (
            car.id,
            car.make,
            car.model,
            car.year,
            car.owner,
            car.isAvailableForAssignment,
            car.isUnderWorkAndPay,
            car.currentDriver,
            car.totalSalesPrice,
            car.installmentAmount,
            car.paymentFrequencyDays,
            car.lastPaymentTime,
            car.amountPaidByDriver,
            car.isPaidOff
        );
    }

    /**
     * @dev Calculates the amount currently due for an installment for a given car.
     * @param _carId The ID of the car.
     * @return The amount due in Wei. Returns 0 if not due or car not under W&P.
     */
    function getAmountDue(uint256 _carId)
        public
        view
        returns (uint256)
    {
        require(_carId > 0 && _carId <= carCount, "Invalid car ID.");
        Car storage car = cars[_carId];

        if (!car.isUnderWorkAndPay || car.isPaidOff) {
            return 0; // Not under W&P or already paid off
        }

        uint256 nextPaymentDueTime = car.lastPaymentTime + (car.paymentFrequencyDays * 1 days);

        if (block.timestamp >= nextPaymentDueTime) {
            // If overdue, the installment is due.
            // If initial assignment and no payment has been made, the first installment is due.
            return car.installmentAmount;
        } else {
            return 0; // Payment not due yet
        }
    }

    /**
     * @dev Retrieves a list of all cars available for a 'Work and Pay' agreement (not yet assigned).
     * @return An array of car IDs that are currently available for assignment.
     */
    function getAvailableWorkAndPayCars() public view returns (uint256[] memory) {
        uint256[] memory availableCars = new uint256[](carCount);
        uint256 currentCount = 0;
        for (uint256 i = 1; i <= carCount; i++) {
            if (cars[i].isAvailableForAssignment) {
                availableCars[currentCount] = cars[i].id;
                currentCount++;
            }
        }
        uint256[] memory result = new uint256[](currentCount);
        for (uint256 i = 0; i < currentCount; i++) {
            result[i] = availableCars[i];
        }
        return result;
    }

    
}
