// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.18 <0.9.0;

import "./NFTSkill.sol";
import "./Employment Smart Contract.sol";

// Ho aggiunto lo SC commentato. Ho implementato la funzione per ottenere la lista di US sulla base del contratto di assunzione
// Ora occorre implementare la presa in carico
// Quindi la parte in cui lo sviluppatore sceglie la US e questa viene definita 'presa in carico'

contract UserStories {

    // Si definiscono le variabili che conterranno l'address del creatore delle User Stories
    // e un valore di supporto per scorrere la lista delle User Stories, corrispondente al valore associato nel mapping
    address public owner;
    
    uint public dimUSList;

    // Si definisce la struttura di ogni User Storie, contenente l'array di skill necessarie, l'effort,
    // lo stato 'disponibile' (false) o 'non disponibile' (true) e l'address dello sviluppatore che la prende in carico
    // (se non disponibile, altrimenti è inizializzato a 0)
    struct UserStory {
        uint[] idSkills;
        uint effort;
        uint payment;
        bool status;
        bool[3] paymentAuthorized;
        bool payed;
        address developer;
    }

    mapping(uint => UserStory) public US;

    // Tramite il costruttore vengono salvati:
    // - l'indirizzo del creatore del contratto
    // - il numero di user stories inserite
    // - i dati di ogni singola user story
    constructor(uint [][] memory _idSkill, uint[] memory _effort, uint[] memory _payment) {
        owner = msg.sender;
        dimUSList = _idSkill[0].length;
        for(uint i = 0; i < dimUSList; i++) {
            US[i].idSkills = _idSkill[i];
            US[i].effort = _effort[i];
            US[i].payment = _payment[i];
        }
    }

    modifier OnlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getSkillsFromEmploymnetContract(address employmentAddress) public view returns (uint [] memory validSkills){
        SkillSelection employmentContract = SkillSelection(employmentAddress);
        return (employmentContract.getSkillList());
    }

    function getAvailableUSList(address employmentAddress) public view returns (uint [] memory) {
        
        uint [] memory validUS = new uint [] (dimUSList);
        uint [] memory employSkills = getSkillsFromEmploymnetContract(employmentAddress);
        bool find;
        uint counter;
        uint validUSIndex; 


        for (uint usIndex = 0; usIndex < dimUSList; usIndex++){
            counter = 0;

            for(uint i = 0; i<US[usIndex].idSkills.length; i++){
                uint currentSkill = US[usIndex].idSkills[i];
                uint j = 0;
                find = false;
                while (!find && j < employSkills.length){
                    if(employSkills[j] == currentSkill) {
                        find = true;
                        counter++;
                        }
                    j++;
                }                
            }
            if (counter == US[usIndex].idSkills.length){
                validUS[validUSIndex] = usIndex;
                validUSIndex++;
            }
        }   
        return validUS;
    }

    // AZ: Lo sviluppatore inserisce in input l'array degli id delle us scelte
    // Passare Emp Add e valid_US per eseguire un controllo

    function USSelection(address employmentAddress, uint [] memory _idSelected) public {

        uint [] memory validUS = new uint [] (dimUSList);
        uint [] memory employSkills = getSkillsFromEmploymnetContract(employmentAddress);
        bool find;
        uint counter;
        uint validUSIndex; 

        for (uint usIndex = 0; usIndex < dimUSList; usIndex++){
            counter = 0;

            for(uint i = 0; i<US[usIndex].idSkills.length; i++){
                uint currentSkill = US[usIndex].idSkills[i];
                uint j = 0;
                find = false;
                while (!find && j < employSkills.length){
                    if(employSkills[j] == currentSkill) {
                        find = true;
                        counter++;
                        }
                    j++;
                }                
            }
            if (counter == US[usIndex].idSkills.length){
                validUS[validUSIndex] = usIndex;
                validUSIndex++;
            }
        }

        for(uint i = 0; i < _idSelected.length; i++) {
            for(uint j = 0; j < validUS.length; j++) {
                if(_idSelected[i] == validUS[j]) {
                    US[_idSelected[i]].status = true;
                    US[_idSelected[i]].developer = msg.sender;
                }
            }
        }
    }

    function getTotalUSList() public view OnlyOwner returns(UserStory [] memory) {
        UserStory [] memory us = new UserStory [] (dimUSList);
        for(uint i = 0; i < dimUSList; i++) {
            us[i].idSkills = US[i].idSkills;
            us[i].effort = US[i].effort;
            us[i].status = US[i].status;
            us[i].developer = US[i].developer;
            us[i].payment = US[i].payment;
        }
        return(us);
    }

    event EmptyList(address owner, string isEmpty);

    function getAddressUSList(address developer) public OnlyOwner returns(UserStory [] memory) {
        uint dimUSListAddress;
        for(uint i = 0; i < dimUSList; i++) {
            if(developer == US[i].developer) {
                dimUSListAddress++;
            }
        }
        UserStory [] memory usAddress = new UserStory [] (dimUSListAddress);
        if(dimUSListAddress > 0) {
            uint counter;
            for(uint i = 0; i < dimUSList; i++) {
                if(developer == US[i].developer) {
                    usAddress[counter].idSkills = US[i].idSkills;
                    usAddress[counter].effort = US[i].effort;
                    usAddress[counter].status = US[i].status;
                    usAddress[counter].developer = US[i].developer;
                    usAddress[counter].payment = US[i].payment;
                    counter++;
                }
            }
        }
        else {
            string memory isEmpty = "L'indirizzo non ha User Stories associate";
            emit EmptyList(owner, isEmpty);
        }
        return(usAddress);       
    }

    function addUS(uint memory _idSkill, uint memory _effort, uint memory _payment) public OnlyOwner returns(uint) {
        US[dimUSList].idSkills = _idSkill;
        US[dimUSList].effort = _effort;
        US[dimUSList].payment = _payment;
        dimUSList++;
        return(dimUSList);
    }

    function sendPayment(uint _idUserStory) public payable {
        require(US[_idUserStory].payed == false, "Il pagamento per questa User Story e' gia' avvenuto");
        bool Authorized = US[_idUserStory].paymentAuthorized[0]&&US[_idUserStory].paymentAuthorized[1]&&US[_idUserStory].paymentAuthorized[2];
        require(Authorized == true, "Non sono presenti tutte le autorizzazioni per inviare il pagamento");
        if (US[_idUserStory].developer == msg.sender || owner == msg.sender) {
            US[_idUserStory].payed = true;
            address payable devAddress = payable(US[_idUserStory].developer);
            devAddress.transfer(US[_idUserStory].payment);
        }
    }
}
