# Settle

This app makes it easy to track who owes you money and how much, as well as how much you owe others.
(This app is minimal and I would like to keep it that way)

### Architecture
``` mermaid
graph LR
    D["Display<br/>You Owe | Owe You"]
    
    Add[Add Entry]
    AddOY["Add 'Owe You'<br/><i>with description</i>"]
    AddYO["Add 'You Owe'<br/><i>with description</i>"]
    
    H["View History"]
    P["View Profile<br/><i>with transaction history</i>"]
    E["Edit Profile<br/>Edit / Delete"]

    %% Relationships
    D --> Add
    Add --> AddOY
    Add --> AddYO

    D --> H
    H -- Search --> P
    P -.-> E
```
### Modules
``` mermaid
    classDiagram
    %% User Class
    class User {
        +int id
        +String name
        +String mobile
        +pays()
        +receives()
    }

    %% Record/Transaction Class
    class Transaction {
        +int id
        +int user_id
        +float amount
        +boolean is_payment
        +String description
        +Date date
    }

    %% Category for organizing transactions
    class Category {
        +int id
        +String name
        +String type  %% 'income' or 'expense'
    }

    %% User-Transaction Relationship
    User "1" --> "*" Transaction : makes

    %% Transaction-Category Relationship
    Transaction "1" --> "0/1" Category : categorized as
```