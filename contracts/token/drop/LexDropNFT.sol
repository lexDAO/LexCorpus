/*
███╗   ██╗███████╗████████╗     ██████╗ ██████╗  ██████╗ ██████╗     
████╗  ██║██╔════╝╚══██╔══╝     ██╔══██╗██╔══██╗██╔═══██╗██╔══██╗    
██╔██╗ ██║█████╗     ██║        ██║  ██║██████╔╝██║   ██║██████╔╝    
██║╚██╗██║██╔══╝     ██║        ██║  ██║██╔══██╗██║   ██║██╔═══╝     
██║ ╚████║██║        ██║███████╗██████╔╝██║  ██║╚██████╔╝██║         
╚═╝  ╚═══╝╚═╝        ╚═╝╚══════╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝
presented by LexDAO LLC
// SPDX-License-Identifier: GPL-3.0-or-later
*/
pragma solidity 0.8.0; 

interface IERC721ListingTransferFrom { // interface for erc721 token listing and `transferFrom()`
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface LexTokenTransferBatch {
    function transferBatch(address[] calldata to, uint256[] calldata value) external;
}

contract LexDropNFT { // drop deposited LexDAO LEX on NFT holders using LEX batch transfer to save gas vs. other airdrop contracts 
    address LEX = 0x63125c0d5Cd9071de9A1ac84c400982f41C697AE;
    
    function dropLumpSumERC20(address erc721, uint256 amount) external { // drop LEX amount evenly on erc721 holders ("I want to spread 100 LEX across all")
        IERC721ListingTransferFrom nft = IERC721ListingTransferFrom(erc721);
        uint256 count;
        uint256 length = nft.totalSupply();
        
        address[] memory holders = new address[](length);
        
        for (uint256 i = 0; i < length; i++) {
            holders.nft.ownerOf(nft.tokenByIndex(count);
            count++;
        }
        
        LexTokenTransferBatch(LEX).transferBatch(holders, amount / length);
    }
}
