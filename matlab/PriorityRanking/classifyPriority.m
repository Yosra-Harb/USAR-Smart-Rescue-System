function priorityLevel = ...
    classifyPriority(priorityScore)
if priorityScore < 0.35

    priorityLevel = "LOW";

elseif priorityScore < 0.45

    priorityLevel = "MEDIUM";

else

    priorityLevel = "HIGH";

end

end