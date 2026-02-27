document.addEventListener("DOMContentLoaded", () => {

    /* --- 1. DOS Text Typing Effect --- */
    const lines = [
        "> INITIALIZING COMM_LINK...",
        "> SIGNAL PROTOCOL: EXTRATERRESTRIAL",
        "> SYNCHRONIZING WITH SECTOR [NULL]",
        "> DETECTING SHARED DOMAIN...",
        "> WARNING: YOU ARE ENTERING THE COLLECTIVE",
        ""
    ];
    let currentLine = 0;
    let currentChar = 0;
    const dosTextContainer = document.getElementById("dos-text");

    // Create cursor element
    const cursor = document.createElement("span");
    cursor.className = "cursor";

    // We will build the content in an element to easily append text
    const textSpan = document.createElement("span");
    dosTextContainer.appendChild(textSpan);
    dosTextContainer.appendChild(cursor);

    function typeLine() {
        if (currentLine >= lines.length - 1) { // last line is empty just to pause before next phase
            setTimeout(powerOff, 3500); // wait 3.5s before power off
            return;
        }

        const line = lines[currentLine];
        if (currentChar < line.length) {
            textSpan.innerHTML += line.charAt(currentChar);
            currentChar++;
            // Faster typing speed for longer text (10ms - 30ms)
            setTimeout(typeLine, Math.random() * 20 + 10);
        } else {
            textSpan.innerHTML += "<br>";
            currentLine++;
            currentChar = 0;
            // Pause slightly between lines
            setTimeout(typeLine, 150);
        }
    }

    // Start typing after a short delay
    setTimeout(typeLine, 800);

    /* --- 2. Screen Transition --- */
    function powerOff() {
        const dosScreen = document.getElementById("dos-screen");
        // Trigger CRT power-off animation
        dosScreen.classList.add("power-off");

        // Wait for animation to mostly finish, then switch scenes
        setTimeout(() => {
            dosScreen.classList.remove("active");
            startNeonScene();
        }, 600);
    }

    /* --- 3. Neon Scene & Static Background --- */
    function startNeonScene() {
        const neonScreen = document.getElementById("neon-screen");
        neonScreen.classList.add("active");

        // Start TV Static
        initStatic();

        // Trigger massive background neon haze
        document.getElementById("neon-content").classList.add("haze-on");

        // Trigger text flicker animations
        setTimeout(() => {
            document.querySelector(".welcome-text").classList.add("flicker-in");
            document.querySelector(".oga-logo").classList.add("flicker-in");
            document.querySelector(".enter-now").classList.add("flicker-in");
        }, 100);
    }

    /* Canvas TV Static Implementation */
    function initStatic() {
        const canvas = document.getElementById("static-canvas");
        const ctx = canvas.getContext("2d", { alpha: false });
        let w, h;

        function resizeCanvas() {
            // Cut resolution in half for performance and chunky CRT look
            w = canvas.width = Math.floor(window.innerWidth / 2);
            h = canvas.height = Math.floor(window.innerHeight / 2);
            // Stretch the heavily pixelated canvas back to full screen
            canvas.style.width = window.innerWidth + "px";
            canvas.style.height = window.innerHeight + "px";
        }

        window.addEventListener("resize", resizeCanvas);
        resizeCanvas();

        function drawNoise() {
            const idata = ctx.createImageData(w, h);
            const buffer32 = new Uint32Array(idata.data.buffer);
            const len = buffer32.length;

            for (let i = 0; i < len; i++) {
                if (Math.random() < 0.6) {
                    buffer32[i] = 0xff000000; // Black (A=255, B=0, G=0, R=0)
                } else {
                    // Dark greyish green for static (A=255, B=0x22, G=0x33, R=0x22)
                    buffer32[i] = 0xff223322;
                }
            }

            ctx.putImageData(idata, 0, 0);

            // Loop roughly at 24fps to look more like analog TV static instead of 60fps blur
            setTimeout(() => {
                requestAnimationFrame(drawNoise);
            }, 1000 / 24);
        }

        drawNoise();
    }

});
