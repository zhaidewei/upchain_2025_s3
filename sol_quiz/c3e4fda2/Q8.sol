/*
Quiz#8
结构体类型

定义一个public struct类型变量Student，包含两个字段name(string)和age(uint8)
补充完整addStudent函数，向students数组中添加新的Student类型值
补充完整getStudent函数，返回students数组下标索引对应值的name和age
*/

pragma solidity ^0.8.0;

contract StructDataType {
    Student[] public students;

    // Student
    struct Student {
        string name;
        uint8 age;
    }

    constructor() {}

    function addStudent(string memory name, uint8 age) public {
        //
        students.push(Student(name, age));
    }

    function getStudent(uint idx) public view returns (string memory, uint8) {
        require(idx < students.length, "Student does not exist!");

        return (students[idx].name, students[idx].age);
    }

}
