import './App.css';

function App() {

  const checkDev = () => process.env.NODE_ENV === 'production'
    ? <></>
    : <>Dev Mode Detected</>;

  return (
    <div className="App">
      <header className="App-header">
      </header>

      <body className="App-body">
        <h1>Hello GDSC</h1>
        {checkDev()}
      </body>
    </div>
  );
}

export default App;
