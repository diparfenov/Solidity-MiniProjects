// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Мercle Tree

//        Sherlock+John+Mary+Lestrade                     
//                     6                                         

//     Sherlock+John        Mary+Lestrade            
//           4                    5                      

// Sherlock        John   Mary        Lestrade
//     0            1       2             3          

contract Tree {
    //массив хешей, который содержит хэши 0,1,2,3,4,5,6
    bytes32[] public hashes;
    string[4] heroes = ["Sherlock", "John", "Mary", "Lestrade"];

    constructor() {
        //в этом цикле хэшируем первые 4 элемента дерева (0,1,2,3) и добаялем в масcив hashes
        for(uint i=0; i < heroes.length; i++) {
            hashes.push(keccak256(abi.encodePacked(heroes[i])));
        }

        //пока n < 0, проходимся по массиву hashes и вычисляем хэши двух соседних хешей, 
        //и последующих соседних хэшей, и доавбляем их также в массив hashes
        //пока не дойдем до того, как один хэш (root)
        uint n = heroes.length;
        uint offset = 0;
        while (n > 0) {
            for(uint i = 0; i < n - 1; i += 2) {
                bytes32 newHash = keccak256(abi.encodePacked(
                    hashes[i + offset], hashes[i + offset + 1]
                ));
                hashes.push(newHash);
            }
            offset += n;
            n = n / 2;
        }
    }

    //вернуть значение последнего хеша - root
    function getRoot() public view returns(bytes32) {
        return hashes[hashes.length - 1];
    }

    //проверить содержится ли в нашем блоке, напрмиер какой-то элемент,
    //пересчиать еще раз и сравнить с root

    //для этого нужен: (сам root, элемент который хотим проверит, индекс этого элемента, 
    //массив хэшей элементов, который нужен для подтверждения) 
    
    //для "Mary" нужен будет элемент "Lestrade" и элемент "Sherlock+John"
    function verify(bytes32 root, bytes32 leaf, uint index, bytes32[] memory proof) public pure returns(bool) {
        bytes32 hash = leaf;

        //получется в данном примере в массиве 2 элемента
        //в первой итерации: записываем в hash хэш ("Mary" и "Lestrade")
        //во второй итерации: записываем в hash хэш ("Sherlock+John" и полученный только что "Mary+Lestrade")
        for(uint i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            //важно четный или нечетный индекс,
            //четный: хэш считается = (этот элемент, элемент справа от него)
            //нечетный: хэш считается = (элемент слева от него, этот элемент)
            if(index % 2 == 0) {
                hash = keccak256(abi.encodePacked(
                    hash, proofElement
                ));
            } else {
                hash = keccak256(abi.encodePacked(
                    proofElement, hash
                ));
            }
            index = index / 2;
        }
        return hash == root;
    }
}
