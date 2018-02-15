$(() => {
    $("#js-input").on('keydown', e => {
        if (e.metaKey && (event.which === 13 || event.keyCode === 13)) {
            try {
                const jsInput = $('#js-input');
                const jsSrc = jsInput.val();
                jsInput.val(null);
                const compiledJs = Babel.transform(jsSrc, {presets: ['es2015']}).code;
                fetch('/', {
                        method: 'POST',
                        body: compiledJs,
                        headers: new Headers({
                            'Content-Type': 'application/javascript'
                        })
                    }
                ).then(resp => resp.text()).then(text => console.debug(text));
            } catch (e) {
                $('#logs').prepend(
                    $('<li></li>').append(
                        $('<pre/>').text(e),
                        $('<details/>').append(
                            $('<pre/>').text(e.stack)
                        )
                    )
                );
            }
            return false;
        }
        return true;
    });

    $("#btn-reload").on('click', () => {
        fetch('/reload', {method: 'POST'})
            .then(resp => resp.text())
            .then(text => console.debug(text));
    })
});