using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CarBehaviour : MonoBehaviour
{
    // Referencing values
    [SerializeField] private float maxEngineSpd; /* The maximum speed that any engine can reach without external forces (including with items).
    Used for speed ratios - for example particles are simulated at a speed of {CURRENT SPEED}/maxEngineSpd */
    [SerializeField] private float linearDrag; // Will need to change based on terrain

    // Components
    private Rigidbody2D rb;
    private ParticleSystem ps;
    private ParticleSystem.EmissionModule emissionModule;
    private ParticleSystem.ColorOverLifetimeModule colorOverLifetimeModule;

    [SerializeField] private ParticleSystem.MinMaxGradient regGradient;
    [SerializeField] private ParticleSystem.MinMaxGradient boostGradient;
    [SerializeField] private float regEmissionSF;
    [SerializeField] private float boostEmissionSF;
    [SerializeField] private float emissionSF;

    // Vehicle stats
    [SerializeField] private float regMaxSpd; // Max speed without powerups
    [SerializeField] private float maxSpd;

    [SerializeField] private float regAcc;
    [SerializeField] private float boostAcc;
    [SerializeField] private float thrusterAcc;
    [SerializeField] private float acc;

    [SerializeField] private float regTurn;
    [SerializeField] private float regDrift;
    [SerializeField] private float regPowerup;

    [SerializeField] private float driftSF;
    [SerializeField] private float powerupSF; // Scale factor for keeping stats similar in value while still balanced

    // Debug
    [SerializeField] private bool terminalVelocity;

    // Turning
    [SerializeField] private float maxRotationPerSec;

    // Powerup
    [SerializeField] private string powerupItem;
    private bool boosting;

	void Start()
	{
        // Physics
        acc = regAcc;
        maxSpd = regMaxSpd;

        // Rigidbody
        rb = gameObject.GetComponent<Rigidbody2D>();
        rb.drag = linearDrag;

        // Particle System
        ps = gameObject.GetComponent<ParticleSystem>();

        emissionModule = ps.emission;
        emissionModule.enabled = true;

        emissionSF = regEmissionSF;

        colorOverLifetimeModule = ps.colorOverLifetime;
        colorOverLifetimeModule.enabled = true;
        colorOverLifetimeModule.color = regGradient;

        // Items
        boosting = false;
	}

	void FixedUpdate()
    {
        var forward = Input.GetButton("Forward");
        var brake = Input.GetButton("Brake/Reverse");
        var turning = Input.GetAxis("Turn");

        // Particle System
        // Assume that the car is moving. See Acceleration for handling if it is not.
        emissionModule.rateOverTime = (rb.velocity.magnitude / maxEngineSpd) * emissionSF;

        // Acceleration
        // issue - can't decelerate while accelerating - should cancel acc to 0
        // issue - not much control over the maximum speed (rb.velocity.magnitude + regAcc is never greater than or equal to regMaxSpd because of the linear drag)

        if (forward && brake)
        {
            // Handbrake Drift
        }
        else if (forward || boosting)
        {
            // Accelerate forwards
            if (rb.velocity.magnitude + acc < maxSpd)
            {
                rb.velocity += new Vector2(rb.transform.up.x, rb.transform.up.y) * acc * Time.fixedDeltaTime;
            }
        }
        else if (brake)
        {
            // Accelerate backwards
            if (rb.velocity.magnitude + acc < maxSpd)
            {
                rb.velocity -= new Vector2(rb.transform.up.x, rb.transform.up.y) * acc * Time.fixedDeltaTime;
            }
        }
        else
        {
            // Not going forwards or reversing, so the particle system assumption was false; revert.
            emissionModule.rateOverTime = 0;
        }

        // Turning
        if (Input.GetAxis("Turn") > 0)
        {
            if (rb.angularVelocity + regTurn * turning < maxRotationPerSec)
            {
                // Accelerates rotation of the car to the right by regTurn degrees/s.
                rb.angularVelocity += regTurn * turning;
            }
            else
            {
                // Already hit max turn speed, or accelerating further would go over max speed. So set speed to max speed.
                rb.angularVelocity = maxRotationPerSec;
            }
        }

        else if (Input.GetAxis("Turn") < 0)
        {
            if (rb.angularVelocity + regTurn * turning > -maxRotationPerSec)
            {
                // Accelerates rotation of the car to the left by regTurn degrees/s.
                rb.angularVelocity += regTurn * turning;
            }
            else
            {
                // Already hit max turn speed, or accelerating further would go over max speed. So set speed to max speed.
                rb.angularVelocity = -maxRotationPerSec;
            }
        }

        // powerupItem
        if (Input.GetButtonDown("Item"))
        {
            switch (powerupItem)
            {
                case "Boost":
                    maxSpd = maxEngineSpd;
                    acc = boostAcc;
                    colorOverLifetimeModule.color = boostGradient;
                    emissionSF = boostEmissionSF;
                    boosting = true;
                
                    StartCoroutine(ResetAfterBoost(regPowerup * powerupSF));
                    powerupItem = "";
                    break;

                case "Thruster":
                    var itemY = Input.GetAxisRaw("ItemY");
                    var itemX = Input.GetAxisRaw("ItemX");
                    if (itemY != 0 && itemX == 0)
                    {
                        print("what");
                        rb.velocity += new Vector2(rb.transform.up.x, rb.transform.up.y) * thrusterAcc * regPowerup * itemY;
                    }
                    else if (itemY == 0 && itemX != 0)
                    {
                        print("correct");
                        // the fuck?
                        rb.velocity += new Vector2(rb.transform.right.x, rb.transform.right.y) * thrusterAcc * regPowerup * itemX;
                    }
                    else
                    {
                        print("default...");
                        rb.velocity += new Vector2(rb.transform.up.x, rb.transform.up.y) * thrusterAcc * regPowerup;
                    }

                    ThrusterSlowdown();
                    powerupItem = "";
                    break;

                default:
                    // User tried to use a powerup but there isn't one.
                    break;
            }
        }
    }

    // Update is called once per frame
    void Update()
    {
    }

    IEnumerator ResetAfterBoost(float time)
	{
        yield return new WaitForSeconds(time);
        acc = regAcc;
        maxSpd = regMaxSpd;
        colorOverLifetimeModule.color = regGradient;
        emissionSF = regEmissionSF;
        boosting = false;
	}

    void ThrusterSlowdown()
    {
        if (rb.velocity.magnitude > maxSpd)
        {
            print("HI");
            rb.drag = linearDrag * regPowerup;
            ThrusterSlowdown();
        }
        else
        {
            // Now car has slowed to an acceptable speed so drag returns to normal.
            rb.drag = linearDrag;
            rb.velocity = new Vector2(rb.transform.up.x, rb.transform.up.y) * maxSpd;
        }
    }
}
