// ----------------------------------------------------------------------------
// Index page tree browsing

document.addEventListener("DOMContentLoaded", function() {
    var items = document.getElementsByClassName("index-tree");
    var nodes = [];

    for (var i = 0; i < items.length; ++i) {
        var node = items[i];
        var parent = node.parentElement;
        if (!parent || parent.tagName.toLowerCase() != "li") {
            continue;
        }
        node.hidden = true;
        parent.style.listStyle = "none";
        var expander = document.createElement("span");
        expander.className = "expander";
        expander.textContent = "\u2795";
        expander.addEventListener("click", function(node) {
            return function(event) {
                if (event.target.tagName.toLowerCase() == "a") {
                    return;
                }
                event.preventDefault();
                event.stopPropagation(true);
                node.hidden = !node.hidden;
                this.textContent = node.hidden ? "\u2795" : "\u2796";
            };
        }(node));

        if (node.parentElement.parentElement.classList.contains("modules")) {
            node.hidden = false;
            expander.textContent = "\u2796";
        }

        parent.insertBefore(expander, parent.firstChild);
        nodes.push({ node, expander });
    }

    if (nodes.length) {
        var toggle = document.createElement("a");
        toggle.href = "#";
        toggle.appendChild(document.createTextNode("Toggle All"));
        toggle.addEventListener("click", function(event) {
            event.preventDefault();

            var hidden = !nodes[1].node.hidden;
            for (var i = 0; i < nodes.length; ++i) {
                nodes[i].node.hidden = hidden;
                nodes[i].expander.textContent = hidden ? "\u2795" : "\u2796";
            }
        });

        var header = document.getElementsByTagName("header")[0];
        header.appendChild(document.createTextNode(" \u2014 "));
        header.appendChild(toggle);
    }
});
