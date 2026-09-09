// Animated starfield background: stars drift slowly toward the viewer,
// giving a "moving through space" effect. Pure canvas, no dependencies.
(function () {
    var canvas = document.getElementById('starfield');
    if (!canvas) return;
    var ctx = canvas.getContext('2d');

    var STAR_COUNT = 220;
    var stars = [];
    var width, height;

    function resize() {
        width = canvas.width = window.innerWidth;
        height = canvas.height = window.innerHeight;
    }

    function makeStar() {
        return {
            x: (Math.random() - 0.5) * width,
            y: (Math.random() - 0.5) * height,
            z: Math.random() * width,
            o: Math.random() * 0.5 + 0.5 // twinkle base opacity
        };
    }

    function init() {
        resize();
        stars = [];
        for (var i = 0; i < STAR_COUNT; i++) {
            stars.push(makeStar());
        }
    }

    function tick() {
        ctx.fillStyle = 'rgba(10, 8, 30, 0.35)'; // trail fade, keeps a subtle motion blur
        ctx.fillRect(0, 0, width, height);

        var cx = width / 2;
        var cy = height / 2;

        for (var i = 0; i < stars.length; i++) {
            var s = stars[i];
            s.z -= 2.2; // speed of travel

            if (s.z <= 0) {
                stars[i] = makeStar();
                stars[i].z = width;
                continue;
            }

            var k = 128.0 / s.z;
            var sx = s.x * k + cx;
            var sy = s.y * k + cy;

            if (sx < 0 || sx >= width || sy < 0 || sy >= height) {
                stars[i] = makeStar();
                stars[i].z = width;
                continue;
            }

            var size = (1 - s.z / width) * 2.2;
            var twinkle = s.o * (0.7 + 0.3 * Math.sin(Date.now() / 500 + i));

            ctx.beginPath();
            ctx.fillStyle = 'rgba(200, 225, 255, ' + twinkle + ')';
            ctx.arc(sx, sy, Math.max(size, 0.4), 0, Math.PI * 2);
            ctx.fill();
        }

        requestAnimationFrame(tick);
    }

    window.addEventListener('resize', init);
    init();
    requestAnimationFrame(tick);
})();
