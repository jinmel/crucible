// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);
}

interface IUniswapV2Router02 {
    function swap(
        address[] memory path,
        uint256 amountIn,
        address factory,
        address recipient,
        bool fromThis
    ) external returns (uint256 amountOut);
}

contract UniswapInterop {
    IUniswapV2Router02 public uniswapRouter;

    event Test();

    // Event definition
    event SwapEvent(
        address startFactory,
        address endFactory,
        address to,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    // Event signature
    string private constant SWAP_EVENT_SIGNATURE =
        "SwapEvent(address,address,address,address,address,uint256,uint256)";
    string private constant TEST_EVENT_SIGNATURE = "Test()";

    constructor(address _uniswapRouterAddress) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
    }

    function test() external {
        emit Test();
    }

    function receiveTest(bytes memory encodedEvent) external {
        // Get the event signature hash
        bytes32 eventSignatureHash = keccak256(
            abi.encodePacked(TEST_EVENT_SIGNATURE)
        );

        // Check if the event signature matches
        require(
            bytes32(encodedEvent) == eventSignatureHash,
            "Invalid EmptyEvent signature"
        );
    }

    // Function to swap tokens
    function swap(
        address _startFactory,
        address _endFactory,
        address _to,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) external {
        // Approve the Uniswap router to spend the input tokens
        IERC20(_tokenIn).approve(address(uniswapRouter), _amountIn);

        // Perform the token swap
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        uint256 amountOut = uniswapRouter.swap(
            path,
            _amountIn,
            _startFactory,
            _to,
            false
        );

        // Emit the Swap event
        emit SwapEvent(
            _startFactory,
            _endFactory,
            _to,
            _tokenOut,
            _tokenIn,
            amountOut, // amountOut
            _amountIn
        );
    }

    function interopSwap(bytes calldata encodedEvent) external {
        // Decode the Swap event
        (
            address startFactory,
            address endFactory,
            address to,
            address tokenIn,
            address tokenOut,
            uint256 amountIn,
            uint256 amountOut
        ) = decodeSwapEvent(encodedEvent);

        // Approve the Uniswap router to do the opposite swap
        IERC20(tokenOut).approve(address(uniswapRouter), amountOut);

        // Perform the token swap
        address[] memory path = new address[](2);
        path[0] = tokenOut;
        path[1] = tokenIn;

        uniswapRouter.swap(path, amountOut, endFactory, to, false);
    }

    // Function to decode the Swap event
    function decodeSwapEvent(
        bytes calldata encodedEvent
    )
        public
        pure
        returns (
            address startFactory,
            address endFactory,
            address to,
            address tokenIn,
            address tokenOut,
            uint256 amountIn,
            uint256 amountOut
        )
    {
        // Get the event signature hash
        bytes32 eventSignatureHash = keccak256(
            abi.encodePacked(SWAP_EVENT_SIGNATURE)
        );

        // Check if the event signature matches
        bytes memory sigHash = new bytes(32);
        require(
            encodedEvent.length >= 32 &&
                bytes32(encodedEvent[:32]) == eventSignatureHash,
            "Invalid Swap event signature"
        );

        // Decode the event parameters
        // The first 32 bytes are the event signature hash, so we start decoding from byte 32
        (
            startFactory,
            endFactory,
            to,
            tokenIn,
            tokenOut,
            amountIn,
            amountOut
        ) = abi.decode(
            encodedEvent[32:],
            (address, address, address, address, address, uint256, uint256)
        );
    }
}
