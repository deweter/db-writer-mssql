<?php
namespace Keboola\DbWriter\Writer;

use Keboola\Csv\CsvFile;
use Keboola\DbWriter\Logger;
use Keboola\DbWriter\Test\BaseTest;
use Keboola\DbWriter\WriterFactory;
use Monolog\Handler\TestHandler;

class MSSQLSSHTest extends BaseTest
{
	const DRIVER = 'mssql';

	/** @var MSSQL */
	private $writer;

	private $config;

	/**
	 * @var TestHandler
	 */
	private $testHandler;

	public function setUp()
	{
		if (!defined('APP_NAME')) {
			define('APP_NAME', 'wr-db-mssql');
		}

		$this->config = $this->getConfig(self::DRIVER);
		$this->config['parameters']['writer_class'] = 'MSSQL';

		$this->config['parameters']['db']['ssh'] = [
			'enabled' => true,
			'keys' => [
				'#private' => $this->getEnv('mssql', 'DB_SSH_KEY_PRIVATE'),
				'public' => $this->getEnv('mssql', 'DB_SSH_KEY_PUBLIC')
			],
			'user' => 'root',
			'sshHost' => 'sshproxy',
			'remoteHost' => 'mssql',
			'remotePort' => '1433',
			'localPort' => '11433',
		];


		$this->testHandler = new TestHandler();

		$logger = new Logger(APP_NAME);
		$logger->setHandlers([$this->testHandler]);

		$writerFactory = new WriterFactory($this->config['parameters']);

		$this->writer = $writerFactory->create($logger);
		$conn = $this->writer->getConnection();

		$tables = $this->config['parameters']['tables'];

		foreach ($tables as $table) {
			$conn->exec(sprintf("IF OBJECT_ID('%s', 'U') IS NOT NULL DROP TABLE %s", $table['dbName'], $table['dbName']));
		}
	}

	public function testWriteMssql()
	{
		$tables = $this->config['parameters']['tables'];

		// simple table
		$table = $tables[0];
		$sourceTableId = $table['tableId'];
		$outputTableName = $table['dbName'];
		$sourceFilename = $this->dataDir . "/" . $sourceTableId . ".csv";

		$this->writer->drop($outputTableName);
		$this->writer->create($table);
		$this->writer->write(new CsvFile(realpath($sourceFilename)), $table);

		$conn = $this->writer->getConnection();
		$stmt = $conn->query("SELECT * FROM $outputTableName");
		$res = $stmt->fetchAll(\PDO::FETCH_ASSOC);

		$resFilename = tempnam('/tmp', 'db-wr-test-tmp');
		$csv = new CsvFile($resFilename);
		$csv->writeRow(["id","name","glasses"]);
		foreach ($res as $row) {
			$csv->writeRow($row);
		}

		$this->assertFileEquals($sourceFilename, $resFilename);

		// table with special chars
		$table = $tables[1];
		$sourceTableId = $table['tableId'];
		$outputTableName = $table['dbName'];
		$sourceFilename = $this->dataDir . "/" . $sourceTableId . ".csv";

		$this->writer->drop($outputTableName);
		$this->writer->create($table);
		$this->writer->write(new CsvFile(realpath($sourceFilename)), $table);

		$conn = $this->writer->getConnection();
		$stmt = $conn->query("SELECT * FROM $outputTableName");
		$res = $stmt->fetchAll(\PDO::FETCH_ASSOC);

		$resFilename = tempnam('/tmp', 'db-wr-test-tmp-2');
		$csv = new CsvFile($resFilename);
		$csv->writeRow(["col1","col2"]);
		foreach ($res as $row) {
			$csv->writeRow($row);
		}

		$this->assertFileEquals($sourceFilename, $resFilename);

		// ignored columns
		$table = $tables[0];
		$sourceTableId = $table['tableId'];
		$outputTableName = $table['dbName'];
		$sourceFilename = $this->dataDir . "/" . $sourceTableId . ".csv";

		$table['items'][2]['type'] = 'IGNORE';

		$this->writer->drop($outputTableName);
		$this->writer->create($table);
		$this->writer->write(new CsvFile(realpath($sourceFilename)), $table);

		$conn = $this->writer->getConnection();
		$stmt = $conn->query("SELECT * FROM $outputTableName");
		$res = $stmt->fetchAll(\PDO::FETCH_ASSOC);

		$resArr = [];
		foreach ($res as $row) {
			$resArr[] = array_values($row);
		}

		$srcArr = [];
		$csv = new CsvFile($sourceFilename);
		$csv->next();$csv->next();

		while ($csv->current()) {
			$currRow = $csv->current();
			unset($currRow[2]);
			$srcArr[] = array_values($currRow);
			$csv->next();
		}

		$this->assertEquals($srcArr, $resArr);

		$records = $this->testHandler->getRecords();
		$records = array_filter($records, function($record) {
			if ($record['level_name'] != 'DEBUG') {
				return true;
			}

			return false;
		});

		$this->assertCount(2, $records);

		$this->assertArrayHasKey('message', $records[0]);
		$this->assertArrayHasKey('level', $records[0]);
		$this->assertArrayHasKey('message', $records[1]);
		$this->assertArrayHasKey('level', $records[1]);

		$this->assertEquals(Logger::INFO, $records[0]['level']);
		$this->assertRegExp('/Creating SSH tunnel/ui', $records[0]['message']);

		$this->assertEquals(Logger::INFO, $records[1]['level']);
		$this->assertRegExp('/Connecting to DSN/ui', $records[1]['message']);
	}
}
