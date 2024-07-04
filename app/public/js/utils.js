

const Direction = Object.freeze({
    LEFT: 'LEFT',
    UP: 'UP',
    RIGHT: 'RIGHT',
    DOWN: 'DOWN',
});

const getTooltipTranslation = direction => {
        switch (direction) {
            case Direction.LEFT:
                return `translate(-8em, 1em)`;
            case Direction.UP:
                return `translate(0, -2em)`;
            case Direction.RIGHT:
                return `translate(8em, 1em)`;
            case Direction.DOWN:
                return `translate(0, 2em)`;
            default:
                return `translate(0m, 2em)`;
        }
    };


function createTooltip(item, content, direction) {

    const tooltip = document.createElement('div');
    tooltip.classList.add('tooltip');  
    tooltip.innerHTML = content;

    let showTooltipTimeout;

    const showTooltip = (event) => {
        tooltip.style.transform = direction;
        tooltip.style.display = 'block';
    };
    
    const hideTooltip = () => {
        tooltip.style.display = 'none';
        clearTimeout(showTooltipTimeout); // Clear the timeout if the mouse moves out
    };

    item.addEventListener('mouseover', () => {
        showTooltipTimeout = setTimeout(showTooltip, 450); // Delay of 1000ms (1 second)
    });

    item.addEventListener('mouseout', hideTooltip);

    item.appendChild(tooltip);
}

