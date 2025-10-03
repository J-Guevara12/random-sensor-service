# AI Usage reflection

In this case, I useed grok from xAI as my LLM with the crush CLI as my interface, the lack of parameters presented a big gap in comparison to other models (Gemini 2.5 Pro, Gemini 2.5 flash, GPT-4o), but as it's completely free was quite ergonomic to work on as I didn't have to worry about running out of credits.

As this one was a more complex project compared with the previous ones, the AI approach had to be much more refined, these are my key takeaways:

* Act as an architect, or development leader, ask for the model to propose a general schema and refine it.
* Avoid giving it large tasks, divide the challenge into smaller tasks and work each one by one, manually testing everything goes according to plan.
* Sometimes the model takes longer to think about a problem than you to solve it, specially when it has been over many iterations working in the same bug.
* Use it to develop tests, but be aware that the test cases will be mainly proposed by you.
* One of the limitations I encountered, maybe because of the size of the model was that it struggled understanding intermediate rust topics like the borrow checker and lifetimes.
* Another thing I had to be wary about was that the model tried more than once to modify my Cargo.toml file, an innocent change on a personal project, but a guaranteed catastrophe on production systems.
