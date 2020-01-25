pragma solidity ^0.5.0;
import "./CustomERC20.sol";



contract EBookLibrary is CustomERC20{
    
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);

    //********* Variables, Structs, Enums ***********

    address payable admin;
    uint premiumFee;
    uint accessDuration;
	
	enum AccountType {regular, premium}
	mapping (address => AccountType) accoutTypes;
	
	
    enum BookGenre {fiction, novel, poetry, psychology}


    struct Book {
        bool isValid;
        uint accessFee;
        BookGenre bookGenre;
    }

    struct rentInfo{
        address payable renter;
        uint startTime;
        bool available;
    }
    
    //Rented books id to rental information
    mapping (uint => rentInfo) rentedBooks;
    
    //Mapping book id to book specification
    mapping (uint => Book) books;



    //****************** modifiers ******************

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }


    modifier onlyAfterAccessDuration(uint bookId) {
        require(now > rentedBooks[bookId].startTime + accessDuration);
        _;
    }


    modifier onlyIfbookExists(uint bookId) {
        require(books[bookId].isValid == true);
        _; 
    }


    //****************** Constructor ******************

    constructor(uint _totalSupply, string memory _token_name, string memory _token_symbol, uint _accessDuration , uint _premiumFee)
    CustomERC20(_totalSupply, _token_name, _token_symbol, msg.sender) public {
        premiumFee = _premiumFee;
        admin = msg.sender;
        accessDuration = _accessDuration;
    }




    //****************** functions ******************

    // @dev deposit ELTs
    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }
	
	
   // @dev Add a book to books mapping
    function addbook(uint bookId,BookGenre bookGenre,uint accessFee) onlyAdmin public{
        books[bookId] = Book(true,accessFee,BookGenre(bookGenre));
    }
	
	
	
    function changeToPremiun() public payable{
        _transfer(msg.sender, admin, premiumFee);
        accoutTypes[msg.sender] = AccountType.premium;
    }
	
	
	
    
    // @dev Rent a book and give ELTs for the accessFee to the admin(Be careful to cover premium user rule)
    function accesss(uint bookId) payable onlyIfbookExists(bookId) public{
    if(rentedBooks[bookId].available == true)
	   {
	       transfer(admin,books[bookId].accessFee);
	       rentedBooks[bookId].renter = msg.sender;
	       rentedBooks[bookId].startTime = now;
	       rentedBooks[bookId].available = true;
	   }
	 else if(accoutTypes[rentedBooks[bookId].renter] != AccountType.premium && accoutTypes[msg.sender] == AccountType.premium)
	   {
	       _transfer(admin,rentedBooks[bookId].renter,books[bookId].accessFee);
	       transfer(admin,books[bookId].accessFee);
	       rentedBooks[bookId].renter = msg.sender;
	       rentedBooks[bookId].startTime = now;
	       rentedBooks[bookId].available = true;
	       
	   }
    }


    // @dev revokes the renter's access to the book if the access duration has ended.
    function revoke(uint bookId) onlyAdmin() onlyAfterAccessDuration(bookId) public{
        rentedBooks[bookId].available = false;
        rentedBooks[bookId].startTime = 0;
    }


 

    /**
     * @dev Get the state of a book
     * you can use this function for debugging purposes
     * @param bookId, ID of the book
     * @return bookGenre, genre of the book
     * @return accessFee, accessFee of the book
     * @return startTime, Start time of reting period
     * @return renter, Address of the renter
     * @return available, availablity of the book
     */
    function getBook(uint bookId) public view 
    returns(  BookGenre ,uint ,uint ,address ,bool){
        Book memory book = books[bookId];
        return (
            book.bookGenre,
            book.accessFee,
            rentedBooks[bookId].startTime,
            rentedBooks[bookId].renter,
            rentedBooks[bookId].available
            );
    }
	
	
	
	/**
     * @dev any user that wants to exit this library can call this function in order to withdraw his/her ELTs
     * @param amount, the amount of ELTs that user wants to convert to Ether
     */
    function withdraw(uint amount) public {
        require(balanceOf(msg.sender) >= amount);
        address payable recipient = msg.sender;
        recipient.transfer(amount);
        _burn(msg.sender, amount);
        emit Withdrawal(recipient, amount);
  }
	

}                              


                         
